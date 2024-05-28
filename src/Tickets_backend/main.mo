import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Hash "mo:base/Hash";

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

actor {
    var events = HashMap.HashMap<Nat, Event>(0, Nat.equal, Hash.hash);
    var tickets = HashMap.HashMap<Nat, Ticket>(0, Nat.equal, Hash.hash);

    // Create a new event
    public shared ({ caller }) func createEvent(newEvent : Event) : async Nat {
        let eventId = await createEventHelper(newEvent);
        return eventId;
    };

    private func createEventHelper(newEvent : Event) : async Nat {
        let eventId = Nat.fromNat(events.size());
        events.put(eventId, {
            id = eventId;
            name = newEvent.name;
            venue = newEvent.venue;
            startTime = newEvent.startTime;
            endTime = newEvent.endTime;
            totalTickets = newEvent.totalTickets;
            remainingTickets = newEvent.totalTickets;
            description = newEvent.description;
        });
        return eventId;
    };

    // Create a new ticket for an event
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
                    let ticketId = Nat.fromNat(tickets.size());
                    let newTicket : Ticket = {
                        id = ticketId;
                        eventId = eventId;
                        holderPrincipal = caller;
                        price = price;
                        issuedAt = Int.abs(Time.now());
                    };
                    tickets.put(ticketId, newTicket);
                    events.put(eventId, {
                        id = event.id;
                        name = event.name;
                        venue = event.venue;
                        startTime = event.startTime;
                        endTime = event.endTime;
                        totalTickets = event.totalTickets;
                        remainingTickets = event.remainingTickets - 1;
                        description = event.description;
                    });
                    return ticketId;
                };
            };
        };
    };

    // Transfer a ticket to a new principal
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

    // Get details of an event
    public query func getEvent(eventId : Nat) : async ?Event {
        return events.get(eventId);
    };

    // Get details of a ticket
    public query func getTicket(ticketId : Nat) : async ?Ticket {
        return tickets.get(ticketId);
    };

    // Get all events
    public query func getAllEvents() : async [Event] {
        return Iter.toArray(events.vals());
    };

    // Get all tickets for an event
    public query func getEventTickets(eventId : Nat) : async [Ticket] {
        let eventTickets = Iter.filter<Ticket>(tickets.vals(), func(ticket : Ticket) : Bool {
            ticket.eventId == eventId;
        });
        return Iter.toArray(eventTickets);
    };
};