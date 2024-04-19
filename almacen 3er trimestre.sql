create table productos (
    id_producto integer primary key,
    nombre varchar(30),
    stock number
);
/
 
 alter table productos  modify (id_producto integer);
 
create table venta(
    id_venta integer primary key,
    id_producto references productos (id_producto),
    cantidad number (4),
    precio_unidad numeric (5),
    ultimo_precio_venta numeric (5)

);
/


create table compra(
    id_compra integer primary key,
    id_producto references productos (id_producto),
    cantidad number(4),
    precio_proveedor numeric (5),
    ultimo_precio_compra numeric (5)
);


---------------------------VISTAS--------------------------------
create or replace view V_PRODUCTOS(
    nombreproducto,
    idproducto
)as 
select 
    nombre, 
    id_producto
from productos ;
/



-- Ejercicio 4

CREATE OR REPLACE VIEW V_EXISTENCIAS(
    idproducto,
    existencias,
    ultimopreciocompra,
    ultimoprecioventa
) AS
SELECT 
    p.id_producto,
    COALESCE(p.stock, 0), -- Si p.stock es NULL, se reemplaza con 0
    COALESCE((
        SELECT MAX(c.precio_proveedor) 
        FROM compra c 
        WHERE c.id_producto = p.id_producto
    ), NULL), -- Utilizamos COALESCE para establecer NULL si no hay registro de compra
    COALESCE((
        SELECT MAX(v.precio_unidad) 
        FROM venta v 
        WHERE v.id_producto = p.id_producto
    ), NULL) -- Utilizamos COALESCE para establecer NULL si no hay registro de venta
FROM productos p;


select p.id_producto as idproducto, p.stock as existencias , c.precio_proveedor as ultimopreciocompra, v.precio_unidad as ultimoprecioventa
from productos p 
join compra c on p.id_producto = c.id_producto
join venta v on p.id_producto = v.id_producto;
group by p.id_producto , p.stock;


select * from v_existencias;

--------------------------SECUENCIAS--------------------------------
CREATE SEQUENCE nuevo_id_producto;
create sequence nuevo_id_compra;
create sequence nuevo_id_venta;

--------------------------FUNCIONES---------------------------------
create or replace function EXISTENCIAS_PRODUCTO(
    p_idproducto IN number
)return number as
    v_existe number;
    v_stock productos.stock%type;
begin
    -- si no tiene entradas ni salidas devuelve 0
    select count(*) into v_existe from productos where id_producto = p_idproducto;
    if v_existe = 0 OR v_existe is null then
        return -1;
    end if;
    if v_existe <> 0 or v_existe is not null then
        select stock into v_stock from productos where id_producto = p_idproducto;
        return v_stock;
        -- poner el stock que tenga
    end if;
end;
/

set serveroutput on;
begin
dbms_output.put_line(EXISTENCIAS_PRODUCTO(1));
end;
/

-- Ejercicio 5
create or replace function PRECIO_MEDIO_VENTA(
    p_idproducto number
) return number
as
    producto_vendido number;
    precio_medio number(9,2);
    ventas number;
begin 
    select count (*) into producto_vendido from productos where id_producto = p_idproducto;
    if producto_vendido = 0 or producto_vendido is null then
        raise_application_error(-20102,'el producto no existe');
        return null;
    else 
        select sum(precio_unidad * cantidad) into precio_medio from venta where id_producto = p_idproducto;
        select sum(cantidad) into ventas from venta where id_producto = p_idproducto;
        return (precio_medio / ventas);
    end if;
end;
/

set serveroutput on;
begin
dbms_output.put_line(precio_medio_venta(1));
end;
/
-----------------------PROCEDIMIENTOS-------------------------------
-- Ejercicio 2
create or replace procedure CREAR_PRODUCTO (
    p_nombreproducto IN varchar, 
    p_idproducto OUT number
)
AS
    v_producto productos%rowtype;
BEGIN
    --consigo el nuevo id
    p_idproducto := nuevo_id_producto.nextval ;
    
    -- asigno el parametro con el nuevo id al tipo de dato
    v_producto.id_producto := p_idproducto ;
    -- nuevo nombre del producto 
    v_producto.nombre := p_nombreproducto ;
    -- stock como 0
    v_producto.stock := 0;
    
    --inserto los datos 
    insert into productos values v_producto;
END;
/


-- ejercicio 3
create or replace procedure ENTRADA_PRODUCTO(
    p_idproducto IN number,
    p_cantidad IN number,
    p_preciopagadoporunidad IN NUMERIC
)
as
    v_compra compra%rowtype;
    v_producto productos%rowtype;
    v_existe number;
begin

    select count(*) into v_existe from productos where id_producto = p_idproducto;
    
    -- si devuelve -1 (que no existe o es null)
    if v_existe = 0 or v_existe is null then
        raise_application_error(-20102, 'el producto ' || p_idproducto || ' no existe o es nulo');
    end if;

    -- si devuelve 0 (existe)
    if v_existe <> 0 or v_existe is not null then
        -- almaceno los valores de compra
        v_compra.id_compra := nuevo_id_compra.nextval;
        v_compra.id_producto := p_idproducto ;
        v_compra.cantidad := p_cantidad ;
        v_compra.precio_proveedor := p_preciopagadoporunidad ;
        
        -- updateo el stock añadiendo la cantidad
        update productos set stock = stock + p_cantidad where id_producto = p_idproducto;
        
        -- inserto los valores de compra
        insert into compra values v_compra;
    end if;
end;
/

create or replace procedure SALIDA_PRODUCTO(
    p_idproducto IN number,
    p_cantidad IN number,
    p_preciocobradoporunidad IN numeric)
as
    v_venta venta%rowtype;
    v_producto productos%rowtype;
    v_existe number;
begin
   select count(*) into v_existe from productos where id_producto = p_idproducto;
    
    if v_existe = 0 or v_existe is null then
        raise_application_error(-20102, 'el producto ' || p_idproducto || ' no existe o es nulo');
    end if;
    
    if v_existe <> 0 or v_existe is not null then
        -- almaceno los valores de compra
        v_venta.id_venta := nuevo_id_venta.nextval;
        v_venta.id_producto := p_idproducto ;
        v_venta.cantidad := p_cantidad ;
        v_venta.precio_unidad := p_preciocobradoporunidad;
        
        -- updateo el stock añadiendo la cantidad
        update productos set stock = stock - p_cantidad where id_producto = p_idproducto;
        
        -- inserto los valores de compra
        insert into venta values v_venta;
    end if;
end;
/

-- ejercicio 6

create or replace procedure SALIDA_PRODUCTO_CON_STOCK(
    p_idproducto IN number,
    p_cantidad IN number,
    p_preciocobrado IN number
)as
    v_stock number;
    v_existe number;
    idventa number;
    v_venta venta%rowtype;
begin
    select stock into v_stock from productos where id_producto = p_idproducto;
    
    if p_cantidad > v_stock then
        RAISE_APPLICATION_ERROR(-20101,'Rotura de stock');
    end if;
    
    if v_existe <> 0 then
        salida_producto(p_idproducto,p_cantidad,p_preciocobrado);
    end if;  
    
EXCEPTION
    when no_data_found then
        RAISE_APPLICATION_ERROR(-20102,'EL producto no existe');

end;
/

select count (*) from productos where id_producto = 12;


set serveroutput on;

call salida_producto_con_stock(12,30,8);
