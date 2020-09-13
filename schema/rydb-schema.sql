-- MySQL dump 10.13  Distrib 8.0.21, for Linux (x86_64)
--
-- Host: localhost    Database: rydb
-- ------------------------------------------------------
-- Server version	8.0.21

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `rydb`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `rydb` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `rydb`;

--
-- Table structure for table `answer_0`
--

DROP TABLE IF EXISTS `answer_0`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `answer_0` (
  `qid` int NOT NULL,
  `qans` int DEFAULT NULL,
  PRIMARY KEY (`qid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `answer_1`
--

DROP TABLE IF EXISTS `answer_1`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `answer_1` (
  `qid` int NOT NULL,
  `chid` tinyint NOT NULL COMMENT 'Choice number',
  `choice_latex` text COMMENT 'Choice in LaTeX format',
  `choice_html` text COMMENT 'Choice in HTML format',
  `correct` tinyint(1) DEFAULT NULL COMMENT 'True if correct answer',
  PRIMARY KEY (`qid`,`chid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Multiple choice questions (MCQ) with one or more correct answers.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `question`
--

DROP TABLE IF EXISTS `question`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `question` (
  `qid` int NOT NULL AUTO_INCREMENT,
  `userid` int NOT NULL,
  `qparent` int DEFAULT NULL,
  `qlatex` text,
  `qimage` blob,
  `qhtml` text,
  `qtype` int DEFAULT NULL,
  `qcreated_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`qid`),
  KEY `userid` (`userid`),
  CONSTRAINT `question_ibfk_1` FOREIGN KEY (`userid`) REFERENCES `ry_users` (`userid`)
) ENGINE=InnoDB AUTO_INCREMENT=241 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_biblio`
--

DROP TABLE IF EXISTS `ry_biblio`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_biblio` (
  `ref_id` int NOT NULL AUTO_INCREMENT,
  `ref_nick` char(10) NOT NULL,
  `ref_type` tinyint DEFAULT NULL,
  `ref_author` varchar(128) DEFAULT NULL,
  `ref_series` varchar(128) DEFAULT NULL,
  `ref_title` char(128) DEFAULT NULL,
  `ref_isbn10` char(10) DEFAULT NULL,
  `ref_isbn13` char(13) DEFAULT NULL,
  `ref_year` year DEFAULT NULL,
  `ref_publisher` varchar(128) DEFAULT NULL,
  `ref_keywords` varchar(128) DEFAULT NULL,
  `ref_url` text,
  `ref_accessed` date DEFAULT NULL,
  PRIMARY KEY (`ref_id`),
  UNIQUE KEY `ref_nick` (`ref_nick`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_qid_ref`
--

DROP TABLE IF EXISTS `ry_qid_ref`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_qid_ref` (
  `qid` int NOT NULL,
  `ref_id` int NOT NULL,
  `notes` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_qst_notes`
--

DROP TABLE IF EXISTS `ry_qst_notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_qst_notes` (
  `note_id` int NOT NULL AUTO_INCREMENT,
  `no_qid` int NOT NULL,
  `no_userid` int NOT NULL,
  `no_note` text NOT NULL,
  `no_diagram` blob,
  `no_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`note_id`),
  KEY `no_c1` (`no_qid`),
  KEY `no_c2` (`no_userid`),
  CONSTRAINT `no_c1` FOREIGN KEY (`no_qid`) REFERENCES `question` (`qid`),
  CONSTRAINT `no_c2` FOREIGN KEY (`no_userid`) REFERENCES `ry_users` (`userid`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_qst_types`
--

DROP TABLE IF EXISTS `ry_qst_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_qst_types` (
  `qst_type_id` int NOT NULL AUTO_INCREMENT,
  `qst_type_name` char(64) NOT NULL,
  PRIMARY KEY (`qst_type_id`),
  UNIQUE KEY `qst_type_name` (`qst_type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_script_acl`
--

DROP TABLE IF EXISTS `ry_script_acl`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_script_acl` (
  `acl_userid` int NOT NULL,
  `acl_script` char(32) NOT NULL,
  PRIMARY KEY (`acl_userid`,`acl_script`),
  CONSTRAINT `acl_c1` FOREIGN KEY (`acl_userid`) REFERENCES `ry_users` (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_sessions`
--

DROP TABLE IF EXISTS `ry_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_sessions` (
  `sid` char(35) NOT NULL,
  `userid` int NOT NULL,
  `start` timestamp NOT NULL,
  `stop` timestamp NOT NULL,
  PRIMARY KEY (`sid`),
  UNIQUE KEY `userid` (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_test_attempts`
--

DROP TABLE IF EXISTS `ry_test_attempts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_test_attempts` (
  `att_userid` int NOT NULL,
  `att_tst_id` int NOT NULL,
  `att_qid` int NOT NULL,
  `att_given` int DEFAULT NULL,
  `att_when` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`att_userid`,`att_tst_id`,`att_qid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_test_questions`
--

DROP TABLE IF EXISTS `ry_test_questions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_test_questions` (
  `tq_tst_id` int NOT NULL,
  `tq_qid_seq` int NOT NULL,
  `tq_qid` int NOT NULL,
  `tq_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`tq_tst_id`,`tq_qid_seq`),
  KEY `tq_qid` (`tq_qid`),
  CONSTRAINT `c1` FOREIGN KEY (`tq_tst_id`) REFERENCES `ry_tests` (`tst_id`),
  CONSTRAINT `ry_test_questions_ibfk_1` FOREIGN KEY (`tq_qid`) REFERENCES `question` (`qid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_test_reports`
--

DROP TABLE IF EXISTS `ry_test_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_test_reports` (
  `rpt_userid` int NOT NULL,
  `rpt_tst_id` int NOT NULL,
  `rpt_q_total` tinyint unsigned DEFAULT NULL,
  `rpt_q_correct` tinyint unsigned DEFAULT NULL,
  `rpt_q_wrong` tinyint unsigned DEFAULT NULL,
  `rpt_q_skip` tinyint unsigned DEFAULT NULL,
  `rpt_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`rpt_userid`,`rpt_tst_id`),
  KEY `rpt_c2` (`rpt_tst_id`),
  CONSTRAINT `rpt_c1` FOREIGN KEY (`rpt_userid`) REFERENCES `ry_users` (`userid`),
  CONSTRAINT `rpt_c2` FOREIGN KEY (`rpt_tst_id`) REFERENCES `ry_tests` (`tst_id`),
  CONSTRAINT `rpt_c1` CHECK ((((`rpt_q_correct` + `rpt_q_wrong`) + `rpt_q_skip`) = `rpt_q_total`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_test_schedule`
--

DROP TABLE IF EXISTS `ry_test_schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_test_schedule` (
  `sch_userid` int NOT NULL,
  `sch_tst_id` int NOT NULL,
  `sch_from` timestamp NOT NULL,
  `sch_to` timestamp NOT NULL,
  `sch_submitted` tinyint(1) NOT NULL DEFAULT '0',
  `sch_created_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `sch_submit_time` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`sch_userid`,`sch_tst_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_test_types`
--

DROP TABLE IF EXISTS `ry_test_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_test_types` (
  `tst_type_id` int NOT NULL AUTO_INCREMENT,
  `tst_type_name` char(64) NOT NULL,
  PRIMARY KEY (`tst_type_id`),
  UNIQUE KEY `tst_type_name` (`tst_type_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_tests`
--

DROP TABLE IF EXISTS `ry_tests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_tests` (
  `tst_id` int NOT NULL AUTO_INCREMENT,
  `tst_type` int NOT NULL,
  `tst_owner` int NOT NULL,
  `tst_created_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tst_qst_count` int NOT NULL DEFAULT '0',
  `tst_title` char(128) DEFAULT NULL,
  PRIMARY KEY (`tst_id`),
  UNIQUE KEY `tst_title` (`tst_title`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ry_users`
--

DROP TABLE IF EXISTS `ry_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ry_users` (
  `userid` int NOT NULL AUTO_INCREMENT,
  `username` char(10) NOT NULL,
  `token` char(64) NOT NULL,
  `ur_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`userid`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `username_2` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2020-09-13 22:24:00
