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


select * from v_productos;

create or replace view V_EXISTENCIAS(
    idproducto,
    existencias,
    ultimopreciocompra,
    ultimoprecioventa
)as
select 
    p.id_producto,
    p.stock,
    (select * from compra c order by id_compra desc fetch first 1 row only),
    (select * from venta v order by id_venta desc fetch first 1 row only)
    from productos p
;
/
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
begin
    -- si no tiene entradas ni salidas devuelve 0
    select count(*) into v_existe from productos where id_producto = p_idproducto;
    if v_existe = 0 OR v_existe is null then
        return -1;
    end if;
    if v_existe <> 0 or v_existe is not null then
        return 0;
    end if;
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
    v_existe_stock number;
begin
    -- almaceno el resultado de la funcion
    v_existe_stock := existencias_producto(p_idproducto);
    
    -- si devuelve -1 (que no existe o es null)
    if v_existe_stock = -1 then
        raise_application_error(-20102, 'el producto ' || p_idproducto || ' no existe o es nulo');
        update productos set stock = -1 where id_producto = p_idproducto;
    end if;
    
    -- si devuelve 0 (existe)
    if v_existe_stock = 0 then
        update productos set stock = 0 where id_producto = p_idproducto;
        v_compra.id_compra := nuevo_id_compra.nextval;
        v_compra.id_producto := p_idproducto ;
        v_compra.cantidad := p_cantidad ;
        v_compra.precio_proveedor := p_preciopagadoporunidad ;
        insert into compra values v_compra;
    end if;
    
    --actualizar los datos
    update productos set stock = stock + p_cantidad where id_producto = p_idproducto;
end;
/

create or replace procedure SALIDA_PRODUCTO(
    p_idproducto IN number,
    p_cantidad IN number,
    p_preciocobradoporunidad IN numeric)
as
    v_venta venta%rowtype;
    v_producto productos%rowtype;
    v_existe_stock number;
begin
    -- almaceno el resultado de la funcion
    v_existe_stock := existencias_producto(p_idproducto);
    
    -- si devuelve -1 (que no existe o es null)
    if v_existe_stock = -1 then
        raise_application_error(-20102, 'el producto ' || p_idproducto || ' no existe os es nulo');
        update productos set stock = -1 where id_producto = p_idproducto;
    end if;
    
    
    -- si devuelve 0 (existe)
    if v_existe_stock = 0 then
        update productos set stock = 0 where id_producto = p_idproducto;
        v_venta.id_venta := nuevo_id_venta.nextval;
        v_venta.id_producto := p_idproducto ;
        v_venta.cantidad := p_cantidad ;
        v_venta.precio_unidad := p_preciocobradoporunidad ;
        insert into compra values v_venta;
    end if;
    
    --actualizar los datos
    update productos set stock = stock - p_cantidad where id_producto = p_idproducto;
end;
/

