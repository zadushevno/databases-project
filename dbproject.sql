SET GLOBAL local_infile=1;
-- 1. Создание базы и таблиц
DROP DATABASE IF EXISTS Art;
CREATE DATABASE IF NOT EXISTS Art;

-- 1.1 Create 
CREATE TABLE IF NOT EXISTS Art.Artist
    (
    artist_id INT PRIMARY KEY NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    nationality VARCHAR(50) NOT NULL,
    birth SMALLINT NOT NULL,
    death SMALLINT
    );
    
CREATE TABLE IF NOT EXISTS Art.Style
    (
    name VARCHAR(50) NOT NULL,
	style_id INT PRIMARY KEY NOT NULL
    );
    
CREATE TABLE IF NOT EXISTS Art.Subject
    (
    name VARCHAR(50) NOT NULL,
	subject_id INT PRIMARY KEY NOT NULL
    );
    
CREATE TABLE IF NOT EXISTS Art.Museum
    (
    museum_id INT PRIMARY KEY NOT NULL,
    name VARCHAR(50) NOT NULL,
    address VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    url VARCHAR(100) NOT NULL
    );

CREATE TABLE IF NOT EXISTS Art.Work
    (
    work_id INT PRIMARY KEY NOT NULL,
    name VARCHAR(50) NOT NULL,
    artist_id INT NOT NULL,
    style_id INT,
	museum_id INT,
    subject_id INT,
    FOREIGN KEY(style_id) REFERENCES Art.Style(style_id),
    FOREIGN KEY(subject_id) REFERENCES Art.Subject(subject_id),
    FOREIGN KEY(artist_id) REFERENCES Art.Artist(artist_id),
    FOREIGN KEY(museum_id) REFERENCES Art.Museum(museum_id)
    );

-- 1.2 загрузка данных из csv-файлов
LOAD DATA LOCAL INFILE 'D:\\studies\\proga\\4th year\\infosearch & bd\\styles.csv'
INTO TABLE Art.Style
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@dummy, name, style_id);
    
LOAD DATA LOCAL INFILE 'D:\\studies\\proga\\4th year\\infosearch & bd\\artist.csv'
INTO TABLE Art.Artist
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(artist_id, @dummy, first_name, @middle_name, last_name, nationality, @dummy, birth, death)
SET
middle_name = NULLIF(@middle_name, '')
;

LOAD DATA LOCAL INFILE 'D:\\studies\\proga\\4th year\\infosearch & bd\\subjects.csv'
INTO TABLE Art.Subject
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@dummy, name, subject_id);

LOAD DATA LOCAL INFILE 'D:\\studies\\proga\\4th year\\infosearch & bd\\museum.csv'
INTO TABLE Art.Museum
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(museum_id, name, @address, @city, @dummy, @dummy, @country, @phone, @url)
SET
address = NULLIF(@address, ''),
city = NULLIF(@city, ''),
country = NULLIF(@country, ''),
phone  = NULLIF(@phone, ''),
url = NULLIF(@url, '')
;

LOAD DATA LOCAL INFILE 'D:\\studies\\proga\\4th year\\infosearch & bd\\new_works.csv'
INTO TABLE Art.Work
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@dummy, work_id, name, artist_id, @style_id, @museum_id, @subject_id)
SET 
style_id = NULLIF(@style_id, ""),
museum_id = NULLIF(@museum_id, ""),
subject_id = NULLIF(@subject_id, "")
;

-- 1.3 Update
SELECT * FROM Art.Museum;

UPDATE Art.Museum
SET country = 'Russian Federation'
WHERE country = 'Russia';

SELECT * FROM Art.Museum;

-- 3. Select + фильтрация: выберем всех художников, имя которых -- Ян
SELECT * FROM Art.Artist
WHERE first_name = 'Jan';

-- 4. Select + группировка и агрегация: посчитаем средний возраст художников каждой национальности
SELECT Art.Artist.nationality,
AVG(death - birth) AS average_age
FROM Art.Artist
GROUP BY 
Art.Artist.nationality
ORDER BY average_age DESC;


-- 5. SELECT + вложенный запрос: найдем музеи с наибольшим числом картин
SELECT
    Museum.name AS museum_name, Museum.country,
    (SELECT COUNT(*) FROM Art.Work WHERE Art.Work.museum_id = Museum.museum_id) AS total_paintings
FROM
    Art.Museum
ORDER BY
    total_paintings DESC
LIMIT 5;

-- 6. Select + JOIN нескольких таблиц + агрегация и группировка
-- посмотрим, сколько портретов в жанре 'импрессионизм' было написано художниками разных национальностей
SELECT Art.Artist.nationality, COUNT(*) as number_of_paintings
FROM Art.Work
INNER JOIN Art.Style on Art.Style.style_id = Art.Work.style_id
INNER JOIN Art.Subject on Art.Subject.subject_id = Art.Work.subject_id
INNER JOIN Art.Artist on Art.Artist.artist_id = Art.Work.artist_id
WHERE Subject.name = 'Portraits' and Style.name = 'Impressionism'
GROUP BY Art.Artist.nationality;

-- 7. Процедура

-- эта процедура принимает на вход фамилию художника и выводит информацию о количестве картин, хранящихся в разных музеях

DROP PROCEDURE IF EXISTS  GetPaintings ;
DROP PROCEDURE IF EXISTS  GetThemes ;

DELIMITER $$

CREATE PROCEDURE GetPaintings(IN artistLastName VARCHAR(50))
BEGIN
    DECLARE artistId INT;
    SELECT artist_id INTO artistId
    FROM Art.Artist
    WHERE last_name = artistLastName
    LIMIT 1;
    IF artistId IS NOT NULL THEN
        SELECT
            Museum.name AS museum_name,
            COUNT(Work.work_id) AS total_paintings
        FROM
            Art.Museum
        LEFT JOIN
            Art.Work ON Museum.museum_id = Work.museum_id
        WHERE
            Work.artist_id = artistId
        GROUP BY
            Museum.name
		ORDER BY
			total_paintings DESC;
    ELSE
        SELECT 'Artist not found' AS result_message;
    END IF;
END $$

DELIMITER ;

CALL GetPaintings('Monet');

DELIMITER $$

-- эта процедура принимает на вход фамилию художника и выводит информацию о количестве картин на разные темы
CREATE PROCEDURE GetThemes(IN artistLastName VARCHAR(50))
BEGIN
    DECLARE artistId INT;
    SELECT artist_id INTO artistId
    FROM Art.Artist
    WHERE last_name = artistLastName
    LIMIT 1;

    IF artistId IS NOT NULL THEN
        SELECT
            Subject.name AS painting_subject,
            COUNT(Work.work_id) AS paintings_count
        FROM
            Art.Work
        LEFT JOIN
            Art.Subject ON Work.subject_id = Subject.subject_id
        WHERE
            Work.artist_id = artistId
        GROUP BY
            Subject.name
		ORDER BY
			paintings_count DESC;
    ELSE
        SELECT 'Artist not found' AS result_message;
    END IF;
END $$

DELIMITER ;

CALL GetThemes('Mondrian');
CALL GetThemes('Renoir');

-- 8. Триггер: при удалении художника из таблицы Artist будем удалять все его картины из таблицы Work
USE Art;
DELIMITER $$
CREATE TRIGGER DeleteArtist
BEFORE DELETE ON Art.Artist
FOR EACH ROW
BEGIN
	DELETE FROM Art.Work WHERE Art.Work.artist_id = OLD.artist_id;
END $$ 

DELIMITER ;

SELECT * FROM Art.Work
LEFT JOIN Art.Artist ON Work.artist_id = Artist.artist_id
WHERE Artist.last_name = 'Raoux';

DELETE FROM Art.Artist WHERE Art.Artist.last_name = 'Raoux';

SELECT * 
FROM Art.Work
JOIN Art.Artist ON Art.Artist.artist_id = Art.Work.artist_id
WHERE Art.Artist.last_name = 'Raoux';

-- 9. Представление, которое покажет общее количество картин для каждого художника, а также среднюю продолжительность жизни художников

CREATE VIEW ArtistSummary AS
SELECT
    Artist.artist_id,
    Artist.first_name,
    Artist.last_name,
    COUNT(Work.work_id) AS total_paintings,
    (death - birth) AS lifespan
FROM
    Art.Artist
LEFT JOIN
    Art.Work ON Artist.artist_id = Work.artist_id
GROUP BY
    Artist.artist_id, Artist.first_name, Artist.last_name;

SELECT * FROM ArtistSummary
ORDER BY total_paintings DESC, lifespan ASC;