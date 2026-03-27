-- Migrate guilds (basic fields) and guild ranks/membership
INSERT INTO `guilds` (id,name,ownerid,creationdata,motd)
SELECT id,name,ownerid,creationdata,motd FROM `legacy_import`.`guilds`;

SET @maxid = (SELECT IFNULL(MAX(id),0) FROM `guilds`);
SET @ai = @maxid + 1;
SET @s = CONCAT('ALTER TABLE `guilds` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO `guild_ranks` (id,guild_id,name,level)
SELECT id,guild_id,name,level FROM `legacy_import`.`guild_ranks`;

SET @maxid = (SELECT IFNULL(MAX(id),0) FROM `guild_ranks`);
SET @ai = @maxid + 1;
SET @s = CONCAT('ALTER TABLE `guild_ranks` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

INSERT INTO `guild_membership` (player_id,guild_id,rank_id,nick)
SELECT player_id,guild_id,rank_id,nick FROM `legacy_import`.`guild_membership`;
