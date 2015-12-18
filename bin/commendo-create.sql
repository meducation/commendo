SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema commendo
-- -----------------------------------------------------
# CREATE SCHEMA IF NOT EXISTS commendo_created DEFAULT CHARACTER SET utf8 ;
# USE commendo_created ;

-- -----------------------------------------------------
-- Table `Resources`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Resources` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `keybase` VARCHAR(64) NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `groupname` VARCHAR(128) NOT NULL,
  `score` FLOAT NOT NULL,
  `union_score` FLOAT NULL,
  PRIMARY KEY (`id`),
  INDEX `name` (`name` ASC),
  INDEX `groupname` (`groupname` ASC),
  UNIQUE INDEX `keybase-name-groupname` (`keybase` ASC, `name` ASC, `groupname` ASC),
  INDEX `keybase` (`keybase` ASC),
  INDEX `keybase-name-score` (`keybase` ASC, `name` ASC, `score` ASC),
  INDEX `keybase-groupname` (`keybase` ASC, `groupname` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Tags`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `Tags` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `keybase` VARCHAR(64) NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `tag` VARCHAR(64) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `tag` (`tag` ASC),
  UNIQUE INDEX `keybase-name-tag` (`keybase` ASC, `name` ASC, `tag` ASC),
  INDEX `keybase` (`keybase` ASC),
  INDEX `name` (`name` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `UnionScores`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `UnionScores` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `keybase` VARCHAR(64) NOT NULL,
  `name` VARCHAR(128) NOT NULL,
  `union_score` FLOAT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `keybase` (`keybase` ASC),
  INDEX `name` (`name` ASC),
  UNIQUE INDEX `keybase-name` (`keybase` ASC, `name` ASC))
ENGINE = InnoDB;

# USE @schema_name;

DELIMITER $$
# USE @schema_name$$
CREATE DEFINER = CURRENT_USER
TRIGGER `Resources_AFTER_INSERT`
AFTER INSERT ON `Resources` FOR EACH ROW
BEGIN
  SET @union_score = (
    SELECT SUM(score)
    FROM Resources
    WHERE keybase = new.keybase
    AND name = new.name
  );
  INSERT INTO UnionScores (keybase, name, union_score)
  VALUES (new.keybase, new.name, @union_score)
  ON DUPLICATE KEY UPDATE union_score = @union_score;
END$$

# USE @schema_name$$
CREATE DEFINER = CURRENT_USER TRIGGER `Resources_AFTER_UPDATE` AFTER UPDATE ON `Resources` FOR EACH ROW
BEGIN
  SET @union_score = (
    SELECT SUM(score)
    FROM Resources
    WHERE keybase = new.keybase
    AND name = new.name
  );
  UPDATE UnionScores SET union_score = @union_score
  WHERE keybase = new.keybase
  AND name = new.name;
END$$


DELIMITER ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
