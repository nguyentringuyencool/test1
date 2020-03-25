### _getAvailableSlots_  
test case:  
- Input date and City: server returns list of available slots  
- No response: User chooses date and city but there is no result return from the server  

### _getPlayerBookings_  
test case:  
- callerId, Input date, city, playerId: server returns list of all player bookings (courtId, startHour, endHour, venueId, centreId, BookingId)  
- callerId, wrong Input data/City/PlayerId: server returns 'no result is found'  
- wrong/no callerId, Input date, City, PlayerID: server returns 'no result is found'  
