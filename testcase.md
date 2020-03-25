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
- callerId, retrive day/courtId/name Courtld: server return the information of the venue
- wrong/ no callerId, retrieve day/courtId/name CourtId: server 
