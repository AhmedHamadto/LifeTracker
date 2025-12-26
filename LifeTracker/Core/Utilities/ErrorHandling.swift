import SwiftUI
import Combine

// MARK: - Result Type Alias

typealias AppResult<T> = Result<T, AppError>

// MARK: - Async Result Helpers

extension Result where Failure == AppError {
    var appError: AppError? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }

    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
}

// MARK: - Error State

@Observable
final class ErrorState {
    var currentError: AppError?
    var showError: Bool = false

    func present(_ error: AppError) {
        currentError = error
        showError = true
    }

    func present(_ error: Error) {
        present(AppError.from(error))
    }

    func dismiss() {
        showError = false
        currentError = nil
    }
}

// MARK: - Error Alert Modifier

struct ErrorAlertModifier: ViewModifier {
    @Bindable var errorState: ErrorState

    func body(content: Content) -> some View {
        content
            .alert(
                errorState.currentError?.title ?? "Error",
                isPresented: $errorState.showError,
                presenting: errorState.currentError
            ) { error in
                Button("OK") {
                    errorState.dismiss()
                }

                if error.requiresUserAction {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                        errorState.dismiss()
                    }
                }

                if error.isRecoverable {
                    Button("Retry") {
                        errorState.dismiss()
                    }
                }
            } message: { error in
                VStack {
                    Text(error.errorDescription ?? "An unknown error occurred")
                    if let suggestion = error.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
    }
}

extension View {
    func errorAlert(_ errorState: ErrorState) -> some View {
        modifier(ErrorAlertModifier(errorState: errorState))
    }
}

// MARK: - Error Banner View

struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?

    init(error: AppError, onDismiss: @escaping () -> Void, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(error.errorDescription ?? "Unknown error")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer()

            if let onRetry, error.isRecoverable {
                Button(action: onRetry) {
                    Text("Retry")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundStyle(.white)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
        .padding(.horizontal)
    }
}

// MARK: - Try-Catch Helpers

func withAppError<T>(_ operation: () throws -> T) -> AppResult<T> {
    do {
        let result = try operation()
        return .success(result)
    } catch let error as AppError {
        return .failure(error)
    } catch {
        return .failure(.from(error))
    }
}

func withAppError<T>(_ operation: () async throws -> T) async -> AppResult<T> {
    do {
        let result = try await operation()
        return .success(result)
    } catch let error as AppError {
        return .failure(error)
    } catch {
        return .failure(.from(error))
    }
}

// MARK: - Validation Helpers

struct ValidationError: Error {
    let field: String
    let message: String

    var asAppError: AppError {
        .validationFailed(field: field, reason: message)
    }
}

protocol Validatable {
    func validate() throws
}

extension String {
    func validateNotEmpty(fieldName: String) throws {
        if self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError(field: fieldName, message: "cannot be empty")
        }
    }

    func validateMinLength(_ length: Int, fieldName: String) throws {
        if self.count < length {
            throw ValidationError(field: fieldName, message: "must be at least \(length) characters")
        }
    }

    func validateMaxLength(_ length: Int, fieldName: String) throws {
        if self.count > length {
            throw ValidationError(field: fieldName, message: "must be at most \(length) characters")
        }
    }
}

extension Optional where Wrapped == Double {
    func validatePositive(fieldName: String) throws {
        guard let value = self else { return }
        if value < 0 {
            throw ValidationError(field: fieldName, message: "must be positive")
        }
    }

    func validateRange(_ range: ClosedRange<Double>, fieldName: String) throws {
        guard let value = self else { return }
        if !range.contains(value) {
            throw ValidationError(field: fieldName, message: "must be between \(range.lowerBound) and \(range.upperBound)")
        }
    }
}
