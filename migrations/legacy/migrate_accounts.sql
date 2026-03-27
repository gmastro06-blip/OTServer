-- Migrate accounts from legacy_import to target DB

INSERT INTO `accounts` (id,name,password,secret,type,premium_ends_at,email,creation)
SELECT
	id,
	name,
	password,
	NULL AS secret,
	type,
	CASE
		WHEN lastday IS NOT NULL AND lastday > 0 THEN lastday
		WHEN premdays >= 2147483000 THEN 2147483647
		WHEN premdays > 0 AND create_date > 0 THEN create_date + premdays * 86400
		WHEN premdays > 0 THEN UNIX_TIMESTAMP() + premdays * 86400
		ELSE 0
	END AS premium_ends_at,
	email,
	creation
FROM `legacy_import`.`accounts`;

SET @maxid = (SELECT IFNULL(MAX(id),0) FROM `accounts`);
SET @ai = @maxid + 1;
SET @s = CONCAT('ALTER TABLE `accounts` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
