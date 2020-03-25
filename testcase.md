### _getAvailableSlots_  
test case:  
- Input date and City: server returns list of available slots  
- No response: User chooses date and city but there is no result return from the server  

### _getPlayerBookings_  
test case:  
- callerId, Input date, City, PlayerId: server returns list of all player bookings (courtID, startHour, endHour, venueID, centreID)  
- callerId, wrong Input data/City/PlayerId: server returns 'no result is found'  
- wrong/no callerId, Input date, City, PlayerID: server returns 'no result is found'  
  
### _getVenueBooking
test case:
- callerId, Input day/courtId/name Courtld: server return the information of the venue
- wrong/ no callerId, Input day/courtId/name CourtId: server return nothing or may return the Venue Booking of the others
  
### _getPlayerBooking
test case:
- callerId, Input day/cityId/playerId: server retuen the information of player booking
- wrong/ no callerId, Input day/cityId/playerId: server return the day which has been booking or the same name of other users
  
### _getCreateBooking
test case:
- callerId, Input day/ courtId/ start time/ end time: server return the information of booking 
- wrong/ no callerId, Input day/ courtId/ start time/ end time: server return nothing because if the court of created booking is the same with the pending booking of another user
