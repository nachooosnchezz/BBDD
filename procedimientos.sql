-- crear un cliente y los campos NULL se llaman "por definir"
create or replace procedure crear_cliente(p_nombre varchar, p_idcliente out number)
as
    v_existe number;
    v_clientes clientes%rowtype;
begin
    -- secuencia para el id de cliente
     p_idcliente := nuevo_id_cliente.nextval;
    
    -- verificar existencia del cliente
    select count(*) into v_existe from clientes where codigocliente = p_idcliente;
    if v_existe = 0 then
        raise_application_error(-20001,'El cliente ' || p_idcliente || ' no existe');
    else
        v_clientes.codigocliente := p_idcliente;
        v_clientes.nombrecliente := p_nombre ;
        insert into clientes values v_clientes;
    end if;
    
update clientes 
set 
    nombrecontacto = coalesce(nombrecontacto, 'por definir'),
    telefono = coalesce(telefono, 'por definir'),
    fax = coalesce(fax, 'por definir'),
    lineadireccion1 = coalesce(lineadireccion1, 'por definir'),
    lineadireccion2 = coalesce(lineadireccion2, 'por definir'),
    ciudad = coalesce(ciudad, 'por definir'),
    region = coalesce(region, 'por definir'),
    pais = coalesce(pais, 'por definir'),
    codigopostal = coalesce(codigopostal, 'por definir'),
    codigoempleadorepventas = coalesce(codigoempleadorepventas, -1),
    limitecredito = coalesce(limitecredito, -1)
where codigocliente = p_idcliente;

end;
/

create sequence nuevo_id_cliente increment by 1;

-- llamar al procedimiento
declare
    v_id_cliente NUMBER;
begin
    -- Llamada al procedimiento crear_cliente
    crear_cliente('nombre del cliente', v_id_cliente);
    
    -- El ID del cliente creado estará almacenado en v_id_cliente
    DBMS_OUTPUT.PUT_LINE('se creó el cliente con id: ' || v_id_cliente);
end;
/


-- crea un pedido para el cliente, con fecha de hoy, fecha esperada dentro de una semana, estado a 'NUEVO'.
create or replace procedure CREAR_PEDIDO(p_idcliente number, p_idpedido out number)
as
    v_existe number;
    v_pedidos pedidos%rowtype;
begin
    -- almacenar el nuevo id del pedido
        p_idpedido := nuevo_id_pedido.nextval;
        
    --verificar si existe
    select count(*) into v_existe from pedidos where codigopedido = p_idpedido;
    if v_existe <> 0 or v_existe is not null then
        raise_application_error(-20002,'el pedido ' || p_idpedido || ' ya existe');
    end if;
    
    -- almacenar datos en la variable v_pedidos
        v_pedidos.codigopedido := p_idpedido;
        v_pedidos.fechapedido :=  sysdate ;
        v_pedidos.fechaesperada := sysdate + 7;
        v_pedidos.estado := 'nuevo';
        v_pedidos.codigocliente := p_idcliente;

        insert into pedidos values v_pedidos;
    
end;
/
create sequence nuevo_id_pedido increment by 1 start with 129;

declare 
    v_idpedido number;
begin
    crear_pedido(10,v_idpedido);
    
    dbms_output.put_line('id pedido: ' || v_idpedido);
end;
/


-- Crea una línea de pedido, con el precio del catálogo. El número de línea será el de la última línea más uno.
create or replace procedure crear_linea_pedido(
    p_idpedido in number, 
    p_idproducto in varchar2, 
    p_cantidad in number
)as
    v_lineapedido detallepedidos%rowtype;
    v_existepedido number;
    v_existeproducto number;
    v_preciounidad number;
    v_numerolinea number;
begin
    --verificar que el pedido existe
    select count(*) into v_existepedido from pedidos where p_idpedido = codigopedido;
    if v_existepedido = 0 or v_existepedido is null then
        raise_application_error(-20002,'el pedido ' || p_idpedido || ' no existe');
    end if;
    
    -- verificar que el producto existe
    select count(*) into v_existeproducto from productos where codigoproducto = p_idproducto;
    if v_existeproducto = 0 or v_existeproducto is null then
        raise_application_error(-20003,'el producto ' || p_idproducto || ' no existe');
    end if;
    
    select precioventa into v_preciounidad from productos where codigoproducto = p_idproducto;
    select max(numerolinea) + 1 into v_numerolinea from detallepedidos where p_idpedido = codigopedido;
    
    if v_numerolinea is null then
        v_numerolinea := 1;
    end if;
    
    if v_numerolinea <> 0 or v_numerolinea is not null then
        select max(numerolinea) + 1 into v_numerolinea from detallepedidos where p_idpedido = codigopedido;
    end if;
    
    v_lineapedido.codigopedido := p_idpedido ;
    v_lineapedido.codigoproducto := p_idproducto;
    v_lineapedido.cantidad := p_cantidad;
    v_lineapedido.preciounidad := v_preciounidad ;
    v_lineapedido.numerolinea := v_numerolinea ;

    insert into detallepedidos values v_lineapedido;
end;
/


DECLARE
    v_idpedido NUMBER := 118; -- Ingresa el ID del pedido
    v_idproducto varchar2(50) := 'FR-100'; -- Ingresa el ID del producto
    v_cantidad NUMBER := 6; -- Ingresa la cantidad del producto

BEGIN
    -- Llamada al procedimiento crear_linea_pedido
    crear_linea_pedido(v_idpedido, v_idproducto, v_cantidad);
    
    -- Si quieres mostrar un mensaje de confirmación
    DBMS_OUTPUT.PUT_LINE('Línea de pedido creada exitosamente.');
    
    -- Si deseas hacer alguna otra operación después de llamar al procedimiento
    
END;
/

select * from detallepedidos where codigopedido = 115;
