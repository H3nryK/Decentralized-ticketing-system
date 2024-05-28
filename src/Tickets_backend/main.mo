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
kimani@Kimani:~/Tickets$ dfx deploy
Deploying all canisters.
Creating canisters...
Creating canister Tickets_backend...
Creating a wallet canister on the local network.
The wallet canister on the "local" network for user "default" is "bnz7o-iuaaa-aaaaa-qaaaa-cai"
Tickets_backend canister created with canister id: bkyz2-fmaaa-aaaaa-qaaaq-cai
Building canisters...
Error: Failed while trying to deploy canisters.
Caused by: Failed while trying to deploy canisters.
  Failed to build all canisters.
    Failed while trying to build all canisters.
      The build step failed for canister 'bkyz2-fmaaa-aaaaa-qaaaq-cai' (Tickets_backend) with an embedded error: Failed to build Motoko canister 'Tickets_backend'.: Failed to compile Motoko.: Failed to run 'moc'.: The command '"/home/kimani/.cache/dfinity/versions/0.17.0/moc" "/home/kimani/Tickets/src/Tickets_backend/main.mo" "-o" "/home/kimani/Tickets/.dfx/local/canisters/Tickets_backend/Tickets_backend.wasm" "-c" "--debug" "--idl" "--stable-types" "--public-metadata" "candid:service" "--public-metadata" "candid:args" "--actor-idl" "/home/kimani/Tickets/.dfx/local/canisters/idl/" "--actor-alias" "Tickets_backend" "bkyz2-fmaaa-aaaaa-qaaaq-cai" "--package" "base" "/home/kimani/.cache/dfinity/versions/0.17.0/base"' failed with exit status 'exit status: 1'.
Stdout:

Stderr:
/home/kimani/Tickets/src/Tickets_backend/main.mo:24.1-24.7: syntax error [M0001], unexpected token 'stable', expected one of token or <phrase> sequence:
  <eof>
  seplist(<dec>,<semicolon>)

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