--"Fred Crocitto" vive en "New Milford"--
UPDATE student set zip=(select zip FROM zipcode where city like 'New Milford') 
where first_name like 'Fred';

--Pasa grade_type a español--
UPDATE GRADE_TYPE SET DESCRIPTION = 
CASE DESCRIPTION 
    WHEN 'Homework' THEN 'Deberes'
    WHEN 'Midterm' THEN 'Parcial'
    WHEN 'Participation' THEN 'Participacion'
    WHEN 'Project' THEN 'Proyecto'
    WHEN 'Quiz' THEN 'Cuestionario'
    ELSE DESCRIPTION
END;

--Todos los cursos de Java empiezan el 3 de septiembre del 2007.--
UPDATE section set start_date_time = TO_DATE('3/10/2007','DD/MM/YYYY') 
where course_no IN (
select course_no from course where LOWER(description) LIKE '%java%');

--Los teléfonos de estudiantes y profesores se amplían para incluir el prefijo internacional, de 15 a 20 caracteres. El prefijo de todos los teléfonos conocidos es '+1' (Estados Unidos).--
ALTER TABLE STUDENT MODIFY PHONE VARCHAR(20);
ALTER TABLE INSTRUCTOR MODIFY PHONE VARCHAR (20);
UPDATE STUDENT SET PHONE = '+1' || PHONE WHERE PHONE IS NOT NULL;
UPDATE INSTRUCTOR SET PHONE = '+1' || PHONE WHERE PHONE IS NOT NULL;

--Los teléfonos no conocidos de alumnos pasan a ser 'desconocido'.--
UPDATE STUDENT SET PHONE = 'DESCONOCIDO' WHERE PHONE IS NULL;

--Todas la notas parciales de "Intermediate Java Programming" que imparte "Marilyn Frantzen" son un 30.--
UPDATE GRADE SET NUMERIC_GRADE=30 WHERE NUMERIC_GRADE IN (
    SELECT G.NUMERIC_GRADE FROM GRADE g
    JOIN ENROLLMENT e ON E.STUDENT_ID=G.STUDENT_ID
    JOIN SECTION s ON S.SECTION_ID=E.SECTION_ID
    JOIN INSTRUCTOR i ON I.INSTRUCTOR_ID=S.INSTRUCTOR_ID
    JOIN COURSE c ON C.COURSE_NO=S.COURSE_NO
    WHERE GRADE_TYPE_CODE LIKE 'PA'
    AND DESCRIPTION LIKE 'Intermediate Java Programming'
    AND FIRST_NAME LIKE 'Marilyn'
    AND LAST_NAME LIKE 'Frantzen'
);

--El profesor Mr Tom Wojick da un aprobado general a todos sus alumnos en la nota final (80).--
UPDATE GRADE SET NUMERIC_GRADE=80 WHERE NUMERIC_GRADE IN (
    SELECT G.NUMERIC_GRADE FROM INSTRUCTOR I
    JOIN SECTION S ON S.INSTRUCTOR_ID=I.INSTRUCTOR_ID
    JOIN ENROLLMENT e ON E.SECTION_ID=S.SECTION_ID
    JOIN GRADE g ON G.STUDENT_ID=E.STUDENT_ID
    WHERE GRADE_TYPE_CODE LIKE 'FI'
    AND FIRST_NAME LIKE 'Tom'
    AND LAST_NAME LIKE 'Wojick'
);

--Las notas de los cursos de "Nina Schorin" se calcularán solo como la nota del examen final, el resto de notas se ignora (0% de la nota final).--


--La nota final de "Intro to Programming" que imparte "Nina Schorin" será la nota del examen final menos un 10%.--
UPDATE GRADE SET NUMERIC_GRADE = NUMERIC_GRADE * 0.9 WHERE NUMERIC_GRADE IN (
    SELECT G.NUMERIC_GRADE
    FROM INSTRUCTOR I 
    JOIN SECTION S ON S.INSTRUCTOR_ID=I.INSTRUCTOR_ID
    JOIN COURSE C ON C.COURSE_NO=S.COURSE_NO
    JOIN ENROLLMENT E ON E.SECTION_ID=S.SECTION_ID
    JOIN GRADE G ON G.STUDENT_ID=E.STUDENT_ID
    JOIN STUDENT ST ON ST.STUDENT_ID=E.STUDENT_ID
    WHERE GRADE_TYPE_CODE LIKE 'FI'
    AND DESCRIPTION LIKE 'Intro to Programming'
    AND FIRST_NAME LIKE 'Nina'
    AND LAST_NAME LIKE 'Schorin'
);

-- cambiar el prefijo de los telefonos si empieza por 6 o 7

select * from clientes ;

update clientes set telefono = 
case when
    telefono like '6%'
    or telefono like '7%' 
then '+34 ' || telefono
else telefono
end;

update clientes set telefono = '+34 ' ;

insert into gamasproductos (gama , descripciontexto)
select gama || ' oferta', descripciontexto || ' (con tara)' from gamasproductos;

---------------------------------------------

insert into productos (codigoproducto, nombre,gama,proveedor,descripcion, cantidadenstock, precioventa ,precioproveedor)
select 'ofer-' || codigoproducto, 'Oferta de ' || nombre, gama, proveedor, descripcion, cantidadenstock/2, precioventa/2 ,precioproveedor from productos
where gama like 'Ornamentales' ;

update productos set cantidadenstock = 
case 
     when cantidadenstock = 0 or cantidadenstock = 1 then 0
     when mod(cantidadenstock,2) = 0 then cantidadenstock/2
     when mod(cantidadenstock,2) = 1 then (cantidadenstock/2)-1    
end
where codigoproducto like 'OR-%';




select * from productos;

select * from productos where gama like 'Ornamentales' ;

select * from gamasproductos;

rollback;

----------------------------------------------------------------------------

select floor(5/2), ceil(5/2), round(5/2) , 5/2 from dual;









