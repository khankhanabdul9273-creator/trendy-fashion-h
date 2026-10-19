alter table public.products
    add column if not exists gallery_images jsonb not null default '[]'::jsonb,
    add column if not exists color_options jsonb not null default '[]'::jsonb,
    add column if not exists hoverimg text;

create table if not exists public.product_reviews (
    id uuid primary key default gen_random_uuid(),
    product_id text not null,
    product_name text not null default '',
    order_id text not null,
    reviewer_name text not null check (char_length(reviewer_name) between 1 and 60),
    review_text text not null check (char_length(review_text) between 1 and 500),
    rating smallint not null check (rating between 1 and 5),
    created_at timestamptz not null default now(),
    constraint product_reviews_order_product_unique unique (order_id, product_id)
);

alter table public.product_reviews enable row level security;

drop policy if exists "Anyone can read product reviews" on public.product_reviews;
create policy "Anyone can read product reviews"
    on public.product_reviews for select
    to anon, authenticated
    using (true);

drop policy if exists "Anyone can submit product reviews" on public.product_reviews;
create policy "Anyone can submit product reviews"
    on public.product_reviews for insert
    to anon, authenticated
    with check (
        char_length(reviewer_name) between 1 and 60
        and char_length(review_text) between 1 and 500
        and rating between 1 and 5
    );

revoke select, insert on public.product_reviews from anon, authenticated;
grant select (
    id,
    product_id,
    product_name,
    order_id,
    reviewer_name,
    review_text,
    rating,
    created_at
) on public.product_reviews to anon, authenticated;
grant insert (
    product_id,
    product_name,
    order_id,
    reviewer_name,
    review_text,
    rating
) on public.product_reviews to anon, authenticated;

do $$
begin
    if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
       and not exists (
           select 1
           from pg_publication_tables
           where pubname = 'supabase_realtime'
             and schemaname = 'public'
             and tablename = 'product_reviews'
       ) then
        alter publication supabase_realtime add table public.product_reviews;
    end if;
end
$$;
