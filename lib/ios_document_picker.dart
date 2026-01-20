import 'package:ios_document_picker/types.dart';

import 'ios_document_picker_platform_interface.dart';

class IosDocumentPicker {
  Future<List<IosDocumentPickerPath>?> pick(
    IosDocumentPickerType type, {
    bool? multiple,
    List<String>? allowedUtiTypes,

    /// Initial directory, as a URL. Only has an effect on iOS 13+.
    String? directoryUrl,
  }) {
    return IosDocumentPickerPlatform.instance.pick(
      type,
      multiple: multiple,
      allowedUtiTypes: allowedUtiTypes,
      directoryUrl: directoryUrl,
    );
  }

  /// Move (or copy) file from a temporary path to the chosen location.
  Future<IosDocumentPickerPath?> exportFile(String fileUrl,
      {String? directoryUrl}) async {
    final results = await exportFiles([fileUrl], directoryUrl: directoryUrl);
    if (results == null) return null;
    assert(results.length == 1);
    return results.first;
  }

  /// Move (or copy) files from a temporary path to the chosen location.
  Future<List<IosDocumentPickerPath>?> exportFiles(List<String> fileUrls,
      {String? directoryUrl}) {
    return IosDocumentPickerPlatform.instance.pick(
      IosDocumentPickerType.file, // ignored
      forExporting: fileUrls.map(_cleanupFileUrl).toList(),
      directoryUrl: directoryUrl,
    );
  }

  static String _cleanupFileUrl(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || parsed.scheme.isEmpty) {
      // Assume the input is a reference to a file.
      return Uri.file(url).toString();
    }
    return url; // valid URL
  }
}
