import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import '../trust/library_write_reason.dart';

String localizedLibraryWriteReason(
  BuildContext context,
  LibraryWriteDisabledReason reason,
) {
  final strings = AppLocalizations.of(context);
  return switch (reason) {
    LibraryWriteDisabledReason.noValidTrustAnchor =>
      strings.productionTrustAnchorMissing,
    LibraryWriteDisabledReason.libraryMissing =>
      strings.libraryWriteBlockedMissing,
    LibraryWriteDisabledReason.revoked => strings.libraryWriteBlockedRevoked,
    LibraryWriteDisabledReason.stale => strings.libraryWriteBlockedStale,
    LibraryWriteDisabledReason.revocationListExpired =>
      strings.libraryWriteBlockedExpired,
  };
}
