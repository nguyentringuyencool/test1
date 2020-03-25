### _getAvailableSlots_  
test case:  
- Input date and city: server returns list of available slots  
- No response: User chooses date and city but there is no result return from the server  

### _getPlayerBookings_  
test case:  
- callerId, Input date, city, PlayerId: server returns list of all player bookings (courtID, startHour, endHour, venueID, centreID)  
- callerId, wrong Input data/City/PlayerId: server returns PlayerBooking on wrong date/city/player or 'no result is found'  
- wrong/no callerId, Input date, City, PlayerID: server returns 'no result is found'  
  
### _getVenueBooking_
test case:  
- callerId, Input date, venueId: server return the list of all bookings  
- callerId, wrong Input day/venueId: server return VenueBookings on wrong date/venue or 'no result is found'  
- wrong/no callerId, Input day, venueId: server returns 'no result is found'  

### _createBooking_  
test case:  
- callerId, Input date, courtId, start, end, playerId: server creates a booking  
- Two or more users input same date, courtId, start, end: server will accept the first confirm booking and refuse others with
message 'Please select another date'  
- User inputs date, courtId, start, end which have been booked: server refuses booking with message 'Please select another date'  
- wrong/no callerId, Input date, courtId, start time, end time, playerId: server refuses creating booking

### _cancelBooking_
test case:
- callerId, Input bookingId, >24 hours before start time: cancelBooking success  
- callerId, Input bookingId, <24 hours before start time: refuse cancelBooking and return message 'It's too late, babe'  
- callerId, wrong Input booking Id, ><24 before start time: server returns 'No result is found' and refuses cancelBooking  
- wrong/no callerId, Input booking Id, ><24 before start time: refuse cancelBooking  

### _getBookingInfo_  
test case:  
- callerId, Input bookingId: server returns all booking's infomation: cityId, venueId, courtId, day, start, end, playerId, statusId  
- callerId, wrong Input bookingId: server returns 'no result is found'  
- wrong/no callerId, Input booking Id: server returns 'no result is found'  

### _updateBookingPaymentStatus_  
test case:  
- callerId, Input bookingId: update the booking's payment status  
- callerId, wrong Input bookingId: server returns 'no result is found'
- wrong/no callerId, bookingId: server returns 'no result is found'  

### _getNameCity/getNameVenue/getNameCourt/getNameUser_  
test case:  
- for cityId/venueId/courtId/userId: display corresponding name  
- for cityId/venueId/courtId/userId: display cityId/venueId/courtId/userId  
