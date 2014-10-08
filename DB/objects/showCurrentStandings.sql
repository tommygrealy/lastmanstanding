CREATE DEFINER=`lms`@`localhost` PROCEDURE `showCurrentStandings`()
BEGIN
select username, FullName, CompStatus from users where PaymentStatus='Paid';

END