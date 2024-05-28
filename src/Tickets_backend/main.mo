import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

type Ticket = {
  id: Nat;
  eventId: Nat;
  holderPrincipal: Principal;
  price: Nat;
  issuedAt: Int;
};

type Event = {
  id: Nat;
  name: Text;
  venue: Text;
  startTime: Int;
  endTime: Int;
  totalTickets: Nat;
  remainingTickets: Nat;
  description: Text;
};

var events = HashMap.HashMap<Nat, Event>(0, func Nat.equal, ?);
var tickets = HashMap.HashMap<Nat, Ticket>(0, func Nat.equal, ?);

actor {

  // Create a new ticket for an event
  createTicket: (Nat, Nat) -> async Nat;

  // Transfer a ticket to a new Principal
  transferTicket: (Nat, Principal) -> async Bool;

  // Get details of an Event
  getEvent: (Nat) -> async Event;

  // Get details of a Ticket
  getTicket: (Nat) -> async Ticket;

  // Get all events
  getAllEvents: () -> async [Event];
}

public shared ({ caller }) func createEvent(newEvent : Event) : async Nat {
  let eventId = nextEventId;
  nextEventId += 1;

  events.put(eventId, {
    id = eventId;
    name = newEvent.name;
    venue = newEvent.venue;
    startTime = newEvent.startTime;
    endTime = newEvent.endTime;
    totalTickets = newEvent.totalTickets;
    remainingTickets = newEvent.remainingTickets;
    description = newEvent.description;
  });
  return eventId;
};

public shared ({ caller }) func createTicket(eventId : Nat, price : Nat) : async Nat {
  let event = events.get(eventId);

  switch (event) {
    case null {
      return 0;
    };
    case (?event) {
      if (event.remainingTickets == 0) {
        return 0;
      } else {
        let ticketId = nextTicketId;
        nextTicketId += 1;

        let newTicket : Ticket = {
          id = ticketId;
          eventId = eventId;
          holderPrincipal = caller;
          price = price;
          issuedAt = Int.abs(Time.now());
        };

        tickets.put(ticketId, newTicket);
        events.put(eventId, {
          id = eventId;
          name = newEvent.name;
          venue = newEvent.venue;
          startTime = newEvent.startTime;
          endTime = newEvent.endTime;
          totalTickets = newEvent.totalTickets;
          remainingTickets = newEvent.remainingTickets;
          description = newEvent.description;
        });
        
        return ticketId;
      };
    };
  };
};;

public shared ({ caller }) func transferTicket(ticketId : Nat, newHolder : Principal) : async Bool {
  let ticket = tickets.get(ticketId);

  switch (ticket) {
    case null {
      return false;
    };
    case (?ticket) {
      if (ticket.holderPrincipal != caller) {
        return false;
      } else {
        let updatedTicket : Ticket = {
          id = ticket.id;
          eventId = ticket.eventId;
          holderPrincipal = newHolder;
          price = ticket.price;
          issuedAt = ticket.issuedAt;
        };

        tickets.put(ticketId, updatedTicket);
        return true;
      };
    };
  };
};

public query func getEvent(eventId : Nat) : async ?Event {
  return events.get(eventId);
};

public query func getTicket(ticketId : Nat) : async ?Ticket {
  return tickets.get(ticketId);
};

public query func getAllEvents() : async [Event] {
  return Iter.toArray(events.vals());
};

public query func getEventTickets(eventId : Nat) : async [Ticket] {
  let eventTickets = Iter.fromArray(Iter.toArray(tickets.vals()))
                          .filter(func(ticket : Ticket) : Bool {
                            ticket.eventId == eventId;
                          });
  return Iter.toArray(eventTickets);
};