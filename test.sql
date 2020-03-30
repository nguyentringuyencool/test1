DROP DATABASE IF EXISTS booking_app;
CREATE DATABASE booking_app;
USE booking_app;

DROP TABLE IF EXISTS city;
CREATE TABLE city(
  city_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(50) NOT NULL UNIQUE
);

DROP TABLE IF EXISTS center;
CREATE TABLE center(
  center_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(50) NOT NULL UNIQUE,
  city int NOT NULL,
  CONSTRAINT city_fk
	 FOREIGN KEY (city) REFERENCES city (city_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS court;
CREATE TABLE court(
  court_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(50) NOT NULL UNIQUE,
  center int NOT NULL,
  CONSTRAINT center_fk
	 FOREIGN KEY (center) REFERENCES center (center_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS staff;
CREATE TABLE staff(
  staff_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(50) NOT NULL UNIQUE,
  center int NOT NULL,
  CONSTRAINT staff_center_fk
	 FOREIGN KEY (center) REFERENCES center (center_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS customer;
CREATE TABLE customer(
  customer_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name varchar(50) NOT NULL UNIQUE
);

DROP TABLE IF EXISTS booking;
CREATE TABLE booking(
  booking_id int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  date date NOT NULL,
  startHour int NOT NULL,
  startMin int NOT NULL,
  endHour int NOT NULL,
  endMin int NOT NULL,
  court int,
  customer int,
  timestamp timestamp NOT NULL,
  paymentStatus bool DEFAULT FALSE,
  CONSTRAINT court_fk
     FOREIGN KEY (court) REFERENCES court (court_id) ON DELETE CASCADE,
  CONSTRAINT customer_fk
     FOREIGN KEY (customer) REFERENCES customer (customer_id) ON DELETE CASCADE	 
);

DROP PROCEDURE IF EXISTS CreateBooking;
DELIMITER //
CREATE PROCEDURE CreateBooking(
in pdate date, 
in pstartHour int, in pstartMin int, 
in pendHour int, in pendMin int, 
in pcourt varchar(50), in pcustomer varchar(50), in ptimestamp timestamp)
BEGIN
DECLARE openTime datetime;
DECLARE closeTime datetime;
DECLARE startTime datetime;
DECLARE endTime datetime;
DECLARE playTime time;
DECLARE code CHAR(5) DEFAULT '00000';
DECLARE msg TEXT;
DECLARE nrows INT;
DECLARE result TEXT;

-- Handler for Integrity Constraint
DECLARE IntegrityConstraintException CONDITION for 1452;
DECLARE EXIT HANDLER FOR  IntegrityConstraintException
	BEGIN
      GET STACKED DIAGNOSTICS CONDITION 1 @p1 = RETURNED_SQLSTATE;
	  -- Check existence of Court / Customer
	  IF NOT EXISTS(SELECT * FROM court WHERE pcourt = court_id)
	  THEN IF NOT EXISTS(SELECT * FROM customer WHERE pcustomer = customer_id)
		   THEN SELECT @p1, 'CB-111'; -- Court & Customer not existed.
           ELSE SELECT @p1, 'CB-110'; -- Court not existed.
           END IF;
	  ELSEIF NOT EXISTS(SELECT * FROM customer WHERE pcustomer = customer_id)
	  THEN SELECT @p1, 'CB-109'; -- Customer not existed.
      END IF;
	  ROLLBACK;
	END;
-- Handler for Start/End Time Constraint
DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
	  GET STACKED DIAGNOSTICS CONDITION 1 
		@p1 = RETURNED_SQLSTATE, @p2 = MESSAGE_TEXT;
	  SELECT @p1, @p2;
	  ROLLBACK;
	END;
START TRANSACTION;
-- Convert to time format
SELECT 
  date_add(date_add(pdate, INTERVAL 7 HOUR), INTERVAL 0 MINUTE)
  into openTime;
SELECT 
  date_add(date_add(pdate, INTERVAL 21 HOUR), INTERVAL 0 MINUTE)
  into closeTime;  
SELECT 
  date_add(date_add(pdate, INTERVAL pstartHour HOUR), INTERVAL pstartMin MINUTE)
  into startTime;
SELECT 
  date_add(date_add(pdate, INTERVAL pendHour HOUR), INTERVAL pendMin MINUTE)
  into endTime;
SELECT TIMEDIFF(endTime, startTime) into playTime;
-- Throw exception for Start/End Time Constraint
-- CB-001: startTime < DATE(NOW())
IF startTime < DATE(NOW())
THEN 
   SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = 'CB-001'; 
END IF;
-- CB-002: startTime < openTime 
IF  startTime < openTime 
THEN 
   SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = 'CB-002';
END IF;
-- CB-003 endTime > closeTime 
IF  endTime > closeTime 
THEN 
   SIGNAL SQLSTATE '45000'
   SET MESSAGE_TEXT = 'CB-003';
END IF;
-- CB-004: endTime < startTime
IF endTime < startTime
THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'CB-004'; 
END IF;
-- CB-005: playtime invalid (valid: 45m, 1h, 1h15m, 1h30m)
IF (playTime <> MAKETIME(0,45,0) and
    playTime <> MAKETIME(1,0,0) and
    playTime <> MAKETIME(1,15,0) and
    playTime <> MAKETIME(1,30,0))
THEN 
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'CB-005'; 
END IF;
-- CB-006: overlapping booking


IF EXISTS ( SELECT *
			FROM booking
			WHERE ( date = pdate and
				    court = pcourt and
				    TIME(startTime) < MAKETIME(endHour, endMin, 0) and
				    TIME(endTime) > MAKETIME(startHour, startMin, 0) ) )
THEN 
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'CB-006'; 
END IF;
-- CB-007: have pending booking
IF EXISTS ( SELECT *
            FROM booking
			WHERE   customer = pcustomer and
					paymentStatus = 0 and
					date_add(date_add(date, INTERVAL endHour HOUR), INTERVAL endMin MINUTE) < DATE(NOW()) )
THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'CB-007';
END IF;
-- CB-008: no more than 3 bookings
IF 3 <= ( SELECT COUNT(*) FROM booking
			WHERE customer = pcustomer and 
			date_add(date_add(date, INTERVAL endHour HOUR), INTERVAL endMin MINUTE) >= DATE(NOW()) )
THEN
	SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'CB-008';
END IF;
-- Add booking to table
SELECT 'Success!';
INSERT INTO 
	BOOKING (date, startHour, startMin, endHour, endMin, court, customer, timestamp) 
VALUES (pdate, pstartHour, pstartMin, pendHour, pendMin, pcourt, pcustomer, ptimestamp);

END //
DELIMITER ;

-- Stored procedure CANCEL BOOKING
DROP PROCEDURE IF EXISTS CancelBooking;
DELIMITER //
CREATE PROCEDURE CancelBooking(
in pbooking int, in pcustomer int)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
  GET STACKED DIAGNOSTICS CONDITION 1 @p1 = RETURNED_SQLSTATE, @p2 = MESSAGE_TEXT;
  SELECT @p1, @p2;
  ROLLBACK;
END;
START TRANSACTION;

-- CA-001: customer not exist
IF NOT EXISTS ( SELECT * 
				FROM customer
                WHERE customer_id = pcustomer )
THEN SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'CA-001';
-- CA-002: booking not exist
ELSEIF NOT EXISTS ( SELECT * 
				FROM booking
                WHERE booking_id = pbooking )
THEN SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'CA-002';
-- CA-003: this customer not own the booking
ELSEIF NOT EXISTS ( SELECT * 
				FROM booking
                WHERE booking_id = pbooking and customer = pcustomer )
THEN SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'CA-003';
-- CA-004: violates 24 hours before start time
ELSEIF date_add(date(now()),interval 24 hour) >
									( SELECT date_add(date_add(date, INTERVAL startHour HOUR), INTERVAL startMin MINUTE) 
									  FROM booking_app.booking 
									  WHERE booking_id = pbooking)
    THEN SIGNAL SQLSTATE '45000'
         SET MESSAGE_TEXT = 'CA-004';
END IF;

-- Delete the booking
DELETE FROM booking WHERE booking_id = pbooking;
END //
DELIMITER ;

-- Store procedure: ChangePaymentStatus;
DROP PROCEDURE IF EXISTS ChangePaymentStatus;
DELIMITER //
CREATE PROCEDURE ChangePaymentStatus(
in pbooking int, 
in pstaff int, 
in pstatus bool)
BEGIN
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
  GET STACKED DIAGNOSTICS CONDITION 1 @p1 = RETURNED_SQLSTATE, @p2 = MESSAGE_TEXT;
  SELECT @p1, @p2;
  ROLLBACK;
END;
START TRANSACTION;
-- CP-001: staff not exist
IF NOT EXISTS ( SELECT * 
				FROM staff
                WHERE staff_id = pstaff )
THEN SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'CP-001';
-- CP-002: booking not exist
ELSEIF NOT EXISTS ( SELECT * 
				FROM booking
                WHERE booking_id = pbooking )
THEN SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'CP-002';
-- CP-003: this staff has no relationship with the booking (join booking - court - center - staff)
ELSEIF NOT EXISTS ( SELECT b.booking_id, co.court_id, s.staff_id
				FROM booking b, court co, center ce, staff s
				WHERE ( co.court_id = b.court and
						ce.center_id = co.center and
						s.center = ce.center_id and
						b.booking_id = pbooking and
						s.staff_id = pstaff ) )
THEN SIGNAL SQLSTATE '45000'
     SET MESSAGE_TEXT = 'CP-003';
-- change status
ELSE	UPDATE booking
		SET paymentStatus = pstatus
        WHERE booking_id = pbooking;
END IF;
END //
DELIMITER ;
/* scenario */

-- city
INSERT INTO `city` (`city_id`,`name`) VALUES (3,'Can Tho');
INSERT INTO `city` (`city_id`,`name`) VALUES (1,'Ho Chi Minh');
INSERT INTO `city` (`city_id`,`name`) VALUES (2,'Thu Dau Mot');
-- center
INSERT INTO `center` (`center_id`,`name`,`city`) VALUES (1,'HCM_Trong Dong',1);
INSERT INTO `center` (`center_id`,`name`,`city`) VALUES (2,'HCM_Hoa Lu',1);
INSERT INTO `center` (`center_id`,`name`,`city`) VALUES (3,'CT_CMT8',3);
INSERT INTO `center` (`center_id`,`name`,`city`) VALUES (4,'CT_Ninh Kieu',3);
INSERT INTO `center` (`center_id`,`name`,`city`) VALUES (5,'BD_New City',2);
-- court
INSERT INTO `court` (`court_id`,`name`,`center`) VALUES (1,'Court#1',1);
INSERT INTO `court` (`court_id`,`name`,`center`) VALUES (2,'Court#2',2);
INSERT INTO `court` (`court_id`,`name`,`center`) VALUES (3,'Court#3',3);
INSERT INTO `court` (`court_id`,`name`,`center`) VALUES (4,'Court#4',4);
INSERT INTO `court` (`court_id`,`name`,`center`) VALUES (5,'Court#5',5);
-- staff
INSERT INTO `staff` (`staff_id`,`name`,`center`) VALUES (1,'Staff#1',1);
INSERT INTO `staff` (`staff_id`,`name`,`center`) VALUES (2,'Staff#2',2);
INSERT INTO `staff` (`staff_id`,`name`,`center`) VALUES (3,'Staff#3',3);
INSERT INTO `staff` (`staff_id`,`name`,`center`) VALUES (4,'Staff#4',4);
INSERT INTO `staff` (`staff_id`,`name`,`center`) VALUES (5,'Staff#5',5);
-- customer
INSERT INTO `customer` (`customer_id`,`name`) VALUES (1,'Customer#A');
INSERT INTO `customer` (`customer_id`,`name`) VALUES (2,'Customer#B');
INSERT INTO `customer` (`customer_id`,`name`) VALUES (3,'Customer#C');
INSERT INTO `customer` (`customer_id`,`name`) VALUES (998,'Le');
INSERT INTO `customer` (`customer_id`,`name`) VALUES (999,'Luu');
INSERT INTO `customer` (`customer_id`,`name`) VALUES (997,'Van');
-- booking
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (1,'2020-03-31',10,0,11,0,3,999,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (2,'2020-03-31',18,35,19,20,4,999,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (3,'2020-03-31',10,0,11,0,4,999,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (4,'2020-03-20',10,0,11,0,5,999,'2020-03-29 09:27:18',1);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (6,'2020-03-20',10,0,11,0,4,998,'2020-03-29 09:27:18',1);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (7,'2020-03-20',8,0,9,0,4,1,'2020-03-29 09:27:18',1);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (8,'2020-03-21',8,0,9,0,5,2,'2020-03-29 09:27:18',1);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (9,'2020-04-30',8,30,9,0,2,2,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (10,'2020-03-20',10,0,11,0,4,998,'2020-03-29 09:27:18',1);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (104,'2020-04-02',18,40,19,40,4,998,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (105,'2020-04-03',18,40,19,40,4,998,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (106,'2020-04-04',18,40,19,40,4,998,'2020-03-29 09:27:18',0);
INSERT INTO `booking` (`booking_id`,`date`,`startHour`,`startMin`,`endHour`,`endMin`,`court`,`customer`,`timestamp`,`paymentStatus`) VALUES (107,'2020-04-04',8,40,9,40,4,1,'2020-03-29 09:27:18',0);
/* tests */

# CreateBooking (CB) parameters: booking_date, startHour, startMin, endHour, endMin, court_id, customer_id, timestamp

-- CB-001: startTime < DATE(NOW())
	CALL CreateBooking("2020-02-01", 6, 0, 8, 0, 4, 1, "2020-03-29 09:27:18"); 
    -- expected
-- CB-002:
-- CB-003:
-- CB-004:
-- CB-005:
-- CB-006:
-- CB-007:
-- CB-008:
-- CB-009:
-- CB-109: Customer not existed.
-- CB-110: Court not existed.
-- CB-111: Court & Customer not existed.

# ChangePaymentStatus (CP) parameters: booking_id, staff_id, TRUE/FALSE

-- CP-001:
	CALL ChangePaymentStatus('1', '9', TRUE);
-- CP-002:
-- CP-003:

# CancelBooking (CA) parameters: booking_id, customer_id

-- CA-001:
-- CA-002:
-- CA-003:
-- CA-004:
