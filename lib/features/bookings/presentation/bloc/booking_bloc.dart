import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

// ── Events ─────────────────────────────────────────────────────────────────────

abstract class BookingEvent { const BookingEvent(); }

class LoadMyBookingsEvent extends BookingEvent {
  const LoadMyBookingsEvent();
}

class CreateBookingEvent extends BookingEvent {
  final String         restaurantId;
  final String         branchId;
  final int            guestCount;
  final DateTime       bookingDate;
  final String         timeSlot;
  final String?        tableId;
  final String?        specialRequests;
  final List<CartLine>? cartItems;    // sent to backend so partner sees what customer wants
  final double?        cartSubtotal;  // for reference in booking order

  const CreateBookingEvent({
    required this.restaurantId,
    required this.branchId,
    required this.guestCount,
    required this.bookingDate,
    required this.timeSlot,
    this.tableId,
    this.specialRequests,
    this.cartItems,
    this.cartSubtotal,
  });
}

class CancelBookingEvent extends BookingEvent {
  final String bookingId;
  const CancelBookingEvent(this.bookingId);
}

// ── States ─────────────────────────────────────────────────────────────────────

abstract class BookingState { const BookingState(); }

class BookingInitial  extends BookingState {}
class BookingLoading  extends BookingState {}
class BookingCancelled extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<BookingEntity> bookings;
  const BookingsLoaded(this.bookings);
}

class BookingCreated extends BookingState {
  final BookingEntity booking; // needed for payment verification after creation
  const BookingCreated(this.booking);
}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
}

// ── Bloc ───────────────────────────────────────────────────────────────────────

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repo;

  BookingBloc(this._repo) : super(BookingInitial()) {
    on<LoadMyBookingsEvent>(_onLoad);
    on<CreateBookingEvent>(_onCreate);
    on<CancelBookingEvent>(_onCancel);
  }

  Future<void> _onLoad(
      LoadMyBookingsEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final bookings = await _repo.getMyBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreate(
      CreateBookingEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final booking = await _repo.createBooking(
        restaurantId:    event.restaurantId,
        branchId:        event.branchId,
        guestCount:      event.guestCount,
        bookingDate:     event.bookingDate,
        timeSlot:        event.timeSlot,
        tableId:         event.tableId,
        specialRequests: event.specialRequests,
        cartItems:       event.cartItems,
        cartSubtotal:    event.cartSubtotal,
      );
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCancel(
      CancelBookingEvent event, Emitter<BookingState> emit) async {
    try {
      await _repo.cancelBooking(event.bookingId);
      emit(BookingCancelled());
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}