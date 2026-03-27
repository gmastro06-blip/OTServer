-- Migrate houses from legacy_import to target DB
INSERT INTO `houses` (id,owner,paid,warnings,name,rent,town_id,bid,bid_end,last_bid,highest_bidder,size,beds)
SELECT id,owner,paid,warnings,name,rent,town_id,bid,bid_end,last_bid,highest_bidder,size,beds
FROM `legacy_import`.`houses`;

SET @maxid = (SELECT IFNULL(MAX(id),0) FROM `houses`);
SET @ai = @maxid + 1;
SET @s = CONCAT('ALTER TABLE `houses` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
