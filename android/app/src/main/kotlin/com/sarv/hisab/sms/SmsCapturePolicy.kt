package com.sarv.hisab.sms

/**
 * Pure rules the background receiver applies before anything is stored.
 * The real parsing happens in Dart (lib/domain/sms); this only keeps
 * personal chats and OTPs out of the native queue and builds the short
 * amount label shown in the notification.
 */
object SmsCapturePolicy {
    /** Banks send from alphanumeric DLT headers ("AD-HDFCBK"); people send from numbers. */
    fun isBankLikeSender(sender: String): Boolean = sender.any { it.isLetter() }

    private val financialHint = Regex(
        "(debited|credited|spent|withdrawn|a/c|acct|upi|card|rs\\.?\\s?\\d|inr\\s?\\d|₹)",
        RegexOption.IGNORE_CASE,
    )
    private val otpHint = Regex("\\b(otp|one time password|verification code)\\b", RegexOption.IGNORE_CASE)

    /** Whether a message is worth queueing for the Dart ingest pipeline. */
    fun shouldCapture(sender: String, body: String): Boolean =
        isBankLikeSender(sender) && financialHint.containsMatchIn(body)

    /** Whether the message reads like a completed transaction worth a notification. */
    fun shouldNotify(body: String): Boolean =
        !otpHint.containsMatchIn(body) && Regex("(debited|credited|spent|withdrawn|sent|received|paid)", RegexOption.IGNORE_CASE).containsMatchIn(body)

    /** Notification id for one captured SMS, shared by post and cancel. */
    fun notificationId(sender: String, body: String): Int = (sender + body).hashCode()

    /** Whether the group summary should go: none of the remaining Bank SMS notifications is a message. */
    fun summaryOrphaned(activeIds: Collection<Int>, cancelledIds: Collection<Int>, summaryId: Int): Boolean =
        (activeIds - cancelledIds.toSet() - summaryId).isEmpty()

    private val amount = Regex("(?:rs\\.?|inr|₹)\\s*:?\\s*([0-9][0-9,]*(?:\\.\\d{1,2})?)", RegexOption.IGNORE_CASE)

    /** "₹459" or "₹1,250.50" for the first rupee amount in [body], or null. */
    fun amountLabel(body: String): String? {
        val digits = amount.find(body)?.groupValues?.get(1) ?: return null
        val trimmed = digits.removeSuffix(".00").removeSuffix(".0")
        return "₹$trimmed"
    }
}
