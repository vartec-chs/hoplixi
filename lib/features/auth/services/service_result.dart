class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;

  ServiceResult({required this.success, this.message, this.data});

  factory ServiceResult.success({T? data, String? message}) {
    return ServiceResult(success: true, data: data, message: message);
  }

  factory ServiceResult.failure(String message) {
    return ServiceResult(success: false, message: message);
  }
}
