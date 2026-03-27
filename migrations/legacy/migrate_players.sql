-- Migrate players from legacy_import to target DB
-- Note: attempts to convert IPv4 numeric to varbinary using INET6_ATON/INET_NTOA if available.
INSERT INTO `players` (
  id,name,group_id,account_id,level,vocation,health,healthmax,experience,
  lookbody,lookfeet,lookhead,looklegs,looktype,lookaddons,
  lookmount,lookmounthead,lookmountbody,lookmountlegs,lookmountfeet,
  currentmount,randomizemount,direction,maglevel,mana,manamax,manaspent,soul,
  town_id,posx,posy,posz,conditions,cap,sex,lastlogin,lastip,`save`,skull,skulltime,lastlogout,
  blessings,onlinetime,deletion,balance,offlinetraining_time,offlinetraining_skill,stamina,
  skill_fist,skill_fist_tries,skill_club,skill_club_tries,skill_sword,skill_sword_tries,
  skill_axe,skill_axe_tries,skill_dist,skill_dist_tries,skill_shielding,skill_shielding_tries,
  skill_fishing,skill_fishing_tries
)
SELECT
  id,name,group_id,account_id,level,vocation,health,healthmax,experience,
  lookbody,lookfeet,lookhead,looklegs,looktype,lookaddons,
  0 AS lookmount,0 AS lookmounthead,0 AS lookmountbody,0 AS lookmountlegs,0 AS lookmountfeet,
  0 AS currentmount,0 AS randomizemount,2 AS direction,maglevel,mana,manamax,manaspent,soul,
  town_id,posx,posy,posz,conditions,cap,sex,lastlogin,
  -- try to convert numeric IPv4 to varbinary; fallback to 0
  CASE
    WHEN lastip IS NULL OR lastip = 0 THEN 0x00
    ELSE INET6_ATON(INET_NTOA(lastip))
  END AS lastip,
  `save`,skull,skulltime,lastlogout,blessings,onlinetime,deletion,balance,
  offlinetraining_time,offlinetraining_skill,stamina,
  skill_fist,skill_fist_tries,skill_club,skill_club_tries,skill_sword,skill_sword_tries,
  skill_axe,skill_axe_tries,skill_dist,skill_dist_tries,skill_shielding,skill_shielding_tries,
  skill_fishing,skill_fishing_tries
FROM `legacy_import`.`players`;

SET @maxid = (SELECT IFNULL(MAX(id),0) FROM `players`);
SET @ai = @maxid + 1;
SET @s = CONCAT('ALTER TABLE `players` AUTO_INCREMENT = ', @ai);
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
