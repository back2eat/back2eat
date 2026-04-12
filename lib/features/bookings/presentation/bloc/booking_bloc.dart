import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

// ── Events ────────────────────────────────────────────────────────────

abstract class BookingEvent { const BookingEvent(); }

class LoadMyBookingsEvent extends BookingEvent { const LoadMyBookingsEvent(); }

class CreateBookingEvent extends BookingEvent {
  final String restaurantId;
  final String branchId;
  final int guestCount;
  final DateTime bookingDate;
  final String timeSlot;
  final String? tableId;
  final String? specialRequests;

  const CreateBookingEvent({
    required this.restaurantId,
    required this.branchId,
    required this.guestCount,
    required this.bookingDate,
    required this.timeSlot,
    this.tableId,
    this.specialRequests,
  });
}

class CancelBookingEvent extends BookingEvent {
  final String bookingId;
  const CancelBookingEvent(this.bookingId);
}

// ── States ────────────────────────────────────────────────────────────

abstract class BookingState { const BookingState(); }

class BookingInitial extends BookingState {}
class BookingLoading extends BookingState {}

class BookingsLoaded extends BookingState {
  final List<BookingEntity> bookings;
  const BookingsLoaded(this.bookings);
}

class BookingCreated extends BookingState {
  final BookingEntity booking;
  const BookingCreated(this.booking);
}

class BookingCancelled extends BookingState {}

class BookingError extends BookingState {
  final String message;
  const BookingError(this.message);
}

// ── Bloc ──────────────────────────────────────────────────────────────

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _repo;

  BookingBloc(this._repo) : super(BookingInitial()) {
    on<LoadMyBookingsEvent>(_onLoad);
    on<CreateBookingEvent>(_onCreate);
    on<CancelBookingEvent>(_onCancel);
  }

  Future<void> _onLoad(LoadMyBookingsEvent event, Emitter<BookingState> emit) async {
    emit(BookingLoading());
    try {
      final bookings = await _repo.getMyBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateBookingEvent event, Emitter<BookingState> emit) async {
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
      );
      emit(BookingCreated(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onCancel(CancelBookingEvent event, Emitter<BookingState> emit) async {
    try {
      await _repo.cancelBooking(event.bookingId);
      emit(BookingCancelled());
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}