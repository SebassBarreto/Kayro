-- KAYRO · DDL revisado (Entregable 3) · PostgreSQL
-- Ejecutable desde cero: DROP en orden inverso de dependencia, CREATE en orden de dependencia.
 
DROP TABLE IF EXISTS auditoria_resenas;
DROP TABLE IF EXISTS usuario_genero;
DROP TABLE IF EXISTS lista_contenido;
DROP TABLE IF EXISTS contenido_director;
DROP TABLE IF EXISTS contenido_genero;
DROP TABLE IF EXISTS listas_reproduccion;
DROP TABLE IF EXISTS favoritos;
DROP TABLE IF EXISTS resenas;
DROP TABLE IF EXISTS directores;
DROP TABLE IF EXISTS generos;
DROP TABLE IF EXISTS contenidos;
DROP TABLE IF EXISTS usuarios;
 
-- Tablas padre
CREATE TABLE usuarios (
  id_usuario         SERIAL,
  nombre             VARCHAR(100) NOT NULL,
  correo_electronico VARCHAR(100) NOT NULL,
  contrasena         VARCHAR(255) NOT NULL,
  fecha_registro     DATE         NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuario_correo UNIQUE (correo_electronico),
  CONSTRAINT chk_usuario_nombre CHECK (length(trim(nombre)) > 0),
  CONSTRAINT chk_usuario_correo_formato CHECK (correo_electronico LIKE '%_@_%._%'),
  CONSTRAINT chk_usuario_fecha_registro CHECK (fecha_registro <= CURRENT_DATE)
);
 
CREATE TABLE contenidos (
  id_contenido     SERIAL,
  titulo           VARCHAR(150) NOT NULL,
  tipo             VARCHAR(50)  NOT NULL,
  anio_lanzamiento INT          NOT NULL,
  sinopsis         TEXT,
  duracion_min     INT          NOT NULL,
  CONSTRAINT pk_contenido PRIMARY KEY (id_contenido),
  CONSTRAINT uq_contenido_titulo_anio UNIQUE (titulo, anio_lanzamiento),
  CONSTRAINT chk_contenido_titulo CHECK (length(trim(titulo)) > 0),
  CONSTRAINT chk_contenido_tipo CHECK (tipo IN ('Película', 'Serie', 'Documental')),
  CONSTRAINT chk_contenido_anio
    CHECK (anio_lanzamiento BETWEEN 1888 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT + 2),
  CONSTRAINT chk_contenido_duracion CHECK (duracion_min > 0)
);
 
CREATE TABLE generos (
  id_genero     SERIAL,
  nombre_genero VARCHAR(50) NOT NULL,
  CONSTRAINT pk_genero PRIMARY KEY (id_genero),
  CONSTRAINT uq_genero_nombre UNIQUE (nombre_genero),
  CONSTRAINT chk_genero_nombre CHECK (length(trim(nombre_genero)) > 0)
);
 
CREATE TABLE directores (
  id_director     SERIAL,
  nombre_director VARCHAR(100) NOT NULL,
  CONSTRAINT pk_director PRIMARY KEY (id_director),
  CONSTRAINT chk_director_nombre CHECK (length(trim(nombre_director)) > 0)
);
 
-- Tablas con FK
CREATE TABLE resenas (
  id_resena    SERIAL,
  id_usuario   INT  NOT NULL,
  id_contenido INT  NOT NULL,
  calificacion INT  NOT NULL,
  comentario   TEXT,
  fecha        DATE NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT pk_resena PRIMARY KEY (id_resena),
  CONSTRAINT uq_resena_usuario_contenido UNIQUE (id_usuario, id_contenido),
  CONSTRAINT chk_resena_calificacion CHECK (calificacion BETWEEN 1 AND 5),
  CONSTRAINT chk_resena_fecha CHECK (fecha <= CURRENT_DATE),
  CONSTRAINT fk_resena_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_resena_contenido FOREIGN KEY (id_contenido)
    REFERENCES contenidos (id_contenido) ON DELETE RESTRICT ON UPDATE CASCADE
);
 
CREATE TABLE favoritos (
  id_usuario    INT  NOT NULL,
  id_contenido  INT  NOT NULL,
  fecha_marcado DATE NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT pk_favorito PRIMARY KEY (id_usuario, id_contenido),
  CONSTRAINT chk_favorito_fecha CHECK (fecha_marcado <= CURRENT_DATE),
  CONSTRAINT fk_favorito_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_favorito_contenido FOREIGN KEY (id_contenido)
    REFERENCES contenidos (id_contenido) ON DELETE CASCADE ON UPDATE CASCADE
);
 
CREATE TABLE listas_reproduccion (
  id_lista       SERIAL,
  id_usuario     INT          NOT NULL,
  nombre         VARCHAR(100) NOT NULL,
  descripcion    TEXT,
  fecha_creacion DATE         NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT pk_lista PRIMARY KEY (id_lista),
  CONSTRAINT uq_lista_usuario_nombre UNIQUE (id_usuario, nombre),
  CONSTRAINT chk_lista_nombre CHECK (length(trim(nombre)) > 0),
  CONSTRAINT chk_lista_fecha CHECK (fecha_creacion <= CURRENT_DATE),
  CONSTRAINT fk_lista_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE
);
 
-- Tablas intermedias (N:M)
CREATE TABLE contenido_genero (
  id_contenido INT NOT NULL,
  id_genero    INT NOT NULL,
  CONSTRAINT pk_contenido_genero PRIMARY KEY (id_contenido, id_genero),
  CONSTRAINT fk_contgen_contenido FOREIGN KEY (id_contenido)
    REFERENCES contenidos (id_contenido) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_contgen_genero FOREIGN KEY (id_genero)
    REFERENCES generos (id_genero) ON DELETE RESTRICT ON UPDATE CASCADE
);
 
CREATE TABLE contenido_director (
  id_contenido INT NOT NULL,
  id_director  INT NOT NULL,
  CONSTRAINT pk_contenido_director PRIMARY KEY (id_contenido, id_director),
  CONSTRAINT fk_contdir_contenido FOREIGN KEY (id_contenido)
    REFERENCES contenidos (id_contenido) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_contdir_director FOREIGN KEY (id_director)
    REFERENCES directores (id_director) ON DELETE RESTRICT ON UPDATE CASCADE
);
 
CREATE TABLE lista_contenido (
  id_lista     INT NOT NULL,
  id_contenido INT NOT NULL,
  CONSTRAINT pk_lista_contenido PRIMARY KEY (id_lista, id_contenido),
  CONSTRAINT fk_listacont_lista FOREIGN KEY (id_lista)
    REFERENCES listas_reproduccion (id_lista) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_listacont_contenido FOREIGN KEY (id_contenido)
    REFERENCES contenidos (id_contenido) ON DELETE CASCADE ON UPDATE CASCADE
);
 
CREATE TABLE usuario_genero (
 id_usuario INT NOT NULL,
  id_genero  INT NOT NULL,
  CONSTRAINT pk_usuario_genero PRIMARY KEY (id_usuario, id_genero),
  CONSTRAINT fk_usugen_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_usugen_genero FOREIGN KEY (id_genero)
    REFERENCES generos (id_genero) ON DELETE RESTRICT ON UPDATE CASCADE
);
 
-- Auditoría (RNF06): sin FK a resenas porque la reseña ya fue eliminada
CREATE TABLE auditoria_resenas (
  id_auditoria      SERIAL,
  id_resena         INT       NOT NULL,
  id_usuario        INT,
  fecha_eliminacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_auditoria_resena PRIMARY KEY (id_auditoria),
  CONSTRAINT chk_auditoria_id_resena CHECK (id_resena > 0),
  CONSTRAINT fk_audit_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuarios (id_usuario) ON DELETE SET NULL ON UPDATE CASCADE
);
