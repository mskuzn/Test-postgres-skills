--part3
--запросы не тестировались на данных в случае появления их в БД запросы могут быть быстро исправлены/изменены.
  --1)Рассчитать среднюю цену типов товаров по всем аптекам и отсортировать по убыванию (от большей цены к меньшей)


select pharmacy_id,pharmacy_name,pr.prod_type,avg(sl.price) as avg_price from pharma.sales sl
inner join pharma.products pr on pr.id = sl.product_id --можно конечно и по имени
group by pharmacy_id,pharmacy_name,pr.prod_type
order by avg_price desc
;

  --2) Вывести 10 самых продаваемых товаров (по кол-ву упаковок) за май 2019 года по всем аптекам города Краснодара (от большего к меньшему)
  
with products_and_num_packaging as (
  select product_id,product_name, sum(sl.num_packaging) as num_packaging from pharma.sales sl
  inner join pharma.pharmacies phs on phs.location = 'г. Краснодар' and  sl.pharmacy_id = phs.id
  where time_sale >= '2019-05-01 00:00:00'::timestamptz and time_sale < '2019-06-01 00:00:00'::timestamptz -- можно через date_part или extract
  group by product_id,product_name
  order by num_packaging desc
)
,rating as(select row_number() over() as rank_pak,product_id,product_name,num_packaging from products_and_num_packaging) 
 select rank_pak,product_id,product_name,num_packaging from rating where rank_pak <= 10
;
  --3) Вывести товары и кол-во уникальных аптек, где данный товар продавался в течение 2019 года.
select distinct pharmacy_id,pharmacy_name,product_id,product_name from pharma.sales sl where date_part('year', time_sale)::int = 2019 --and product_name = 'имя товара'
;
  --4) Вывести товары, которые в 2018 году не продавались в городе Краснодаре, но продавались где-то еще.
with all_locations as (
  select distinct product_id,product_name,phs.location from pharma.sales sl
  inner join pharma.pharmacies phs on sl.pharmacy_id = phs.id
  where  date_part('year', time_sale)::int = 2018)
  
select product_id,product_name from all_locations where product_id not in (select product_id from all_locations where location = 'г. Краснодар')
;

  --5) Вывести 3 города, в котором находится больше всего аптек.
select location from(
  select row_number() over(order by count(*) desc) as rait, location from pharma.pharmacies
  group by location
) qwer where rait in (1,2,3)
;
  --6) Выбрать товары, которые за 2018 год продавались не менее 10 упаковок в месяц, и среди них выбрать самую дорогую продажу. Вывести поля дата, аптека, город, товар, цена.
--принято допущение, что 10 упаковок в месяц означает не менее 10 упоковок в каждый из месяцев. Надо уточнить у автора ТЗ
--если в описанном топе есть одинаковые по стомости продажи, то они выведутся все
--explain
with monthly_sales as (
  select product_id,product_name,date_part('month', time_sale)::int as month,sum(num_packaging) as num_packaging
  from pharma.sales 
  where date_part('year', time_sale)::int = 2018
  group by product_id,product_name,date_part('month', time_sale)::int
)
,monthly_good_sales as (select product_id,product_name from monthly_sales where num_packaging >=10)
,stabil_monthly_good_sales as (
  select product_id,product_name,count(*) as cou from monthly_good_sales
  group by product_id,product_name)

,good_products as (
  select product_id,product_name from stabil_monthly_good_sales where cou = 12)
,good_sales as (select time_sale,pharmacy_name,product_name,price from pharma.sales where product_id in (select product_id from good_products)

)
,max_prise as (select max(price) as max_prise from good_sales group by time_sale,pharmacy_name,product_name)

--best:
select time_sale,pharmacy_name,product_name,price from good_sales where price = (select max_prise from max_prise)

;
--##############
--part4
  --1) Все продажи за январь 2019 года для аптек города Ставрополя сохранились в базе со знаком минус. Необходимо написать запрос, который исправит кол-во на положительное значение только для данных продаж.

update pharma.sales set price = abs(price) where pharmacy_id in (select id from pharma.pharmacies where location= 'г. Ставрополь');
  --2) Произошло задвоение данных в таблице продаж для аптеки с ИД № 5. Необходимо удалить дубликаты.
--протестировано
DELETE FROM pharma.sales
       WHERE id NOT IN (SELECT MIN(id) FROM pharma.sales
       GROUP BY time_sale,pharmacy_id,pharmacy_name,product_id,product_name,num_packaging,price)
;

