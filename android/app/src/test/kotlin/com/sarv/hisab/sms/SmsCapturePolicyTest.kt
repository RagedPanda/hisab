package com.sarv.hisab.sms

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SmsCapturePolicyTest {
    private val upiDebit = "Rs.459.00 debited from A/c XX1234 on 21-10-26 to swiggy@ybl (UPI Ref No 123456789012). Avl bal Rs.15,541.00"

    @Test
    fun bankHeadersAreBankLikeAndPhoneNumbersAreNot() {
        assertTrue(SmsCapturePolicy.isBankLikeSender("AD-HDFCBK"))
        assertTrue(SmsCapturePolicy.isBankLikeSender("HDFCBK"))
        assertFalse(SmsCapturePolicy.isBankLikeSender("+919876543210"))
    }

    @Test
    fun capturesBankTransactionsOnly() {
        assertTrue(SmsCapturePolicy.shouldCapture("VM-HDFCBK-S", upiDebit))
        assertFalse(SmsCapturePolicy.shouldCapture("+919876543210", upiDebit))
        assertFalse(SmsCapturePolicy.shouldCapture("VM-ZOMATO", "Your order is out for delivery"))
    }

    @Test
    fun otpsAreCapturedButNeverNotified() {
        val otp = "Your OTP for UPI transaction is 123456. Do not share. Amount: Rs.500 debited on approval"
        assertFalse(SmsCapturePolicy.shouldNotify(otp))
        assertTrue(SmsCapturePolicy.shouldNotify(upiDebit))
    }

    @Test
    fun amountLabelTakesTheFirstRupeeAmount() {
        assertEquals("₹459", SmsCapturePolicy.amountLabel(upiDebit))
        assertEquals("₹1,250.50", SmsCapturePolicy.amountLabel("INR 1,250.50 spent on card XX9876"))
        assertNull(SmsCapturePolicy.amountLabel("Your card statement is ready"))
    }

    @Test
    fun notificationBodyFillsPlaceholders() {
        val settings = SmsCaptureSettings.DEFAULT
        assertEquals("₹459 from HDFCBK. Tap to review.", settings.body("₹459", "HDFCBK"))
        assertEquals("From HDFCBK. Tap to review.", settings.body(null, "HDFCBK"))
    }
}
