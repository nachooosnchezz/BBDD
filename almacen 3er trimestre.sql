create table productos (
    id_producto numeric primary key,
    nombre varchar(30),
    stock number,
    precioproveedor numeric,
    precioventa  numeric
);
/

create table clientes (
    id_cliente integer primary key,
    nombre varchar(30)
);
/

create table pedidos(
    id_pedido integer primary key,
    estado varchar(30),
    id_cliente references clientes (id_cliente)
);
/

create table detalle_pedidos(
    id_detalle_pedidos integer primary key,
    id_pedido references pedidos (id_pedido),
    id_producto references productos (id_producto),
    cantidad number
);
/


---------------------------VISTAS--------------------------------
create or replace view V_PRODUCTOS(
    nombreproducto,
    idproducto
)as 
select 
    id_producto, 
    nombre 
from productos ;

--------------------------SECUENCIAS--------------------------------
CREATE SEQUENCE nuevo_id_producto;

-----------------------PROCEDIMIENTOS-------------------------------
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
    
    --inserto los datos 
    insert into productos values v_producto;
END;
/


create or replace procedure ENTRADA_PRODUCTO(
    p_idproducto IN number,
    p_cantidad IN number,
    p_preciopagadoporunidad IN number
)
as
    v_existe number;
begin
    -- verificar que existe el producto
    select count(*) into v_existe from productos where id_producto = p_idproducto;
    if v_existe = 0 or v_existe is null then
        raise_application_error(-20102, 'el producto ' || p_idproducto || 'no existe');
    end if;
    
    --actualizar los datos
    update productos set stock = stock + p_cantidad, precioproveedor = p_preciopagadoporunidad where id_producto = p_idproducto;
end;
/

create or replace procedure SALIDA_PRODUCTO(
    p_idproducto IN number,
    p_cantidad IN number,
    p_preciocobradoporunidad IN number)
as
    v_existe number;
begin
    -- verificar que existe el producto
    select count(*) into v_existe from productos where id_producto = p_idproducto;
    if v_existe = 0 or v_existe is null then
        raise_application_error(-20102, 'el producto ' || p_idproducto || 'no existe');
    end if;
    
     --actualizar los datos
    update productos set stock = stock - p_cantidad, precioventa = p_preciocobradoporunidad where id_producto = p_idproducto;
    
end;
/

