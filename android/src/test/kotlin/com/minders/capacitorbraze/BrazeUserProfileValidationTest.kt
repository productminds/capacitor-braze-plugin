package com.minders.capacitorbraze

import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [Braze.validateUserProfileFields] is the only validation path for
 * `setUserProfile` — Braze has no native-side rule requiring at least one
 * reserved profile field, and `gender`/`dateOfBirth` need this plugin's own
 * parsing before they can be handed to the native SDK, so this plugin must
 * reject an invalid payload itself. These tests call the pure validator
 * directly (no [android.content.Context], no Braze SDK instance involved)
 * so an invalid payload is provably rejected before any native setter is
 * ever reached.
 */
class BrazeUserProfileValidationTest {

    private val implementation = Braze()

    @Test
    fun setUserProfileRejectsWhenNoFieldsPresent() {
        val exception =
            assertThrows(IllegalArgumentException::class.java) {
                implementation.validateUserProfileFields(
                    email = null,
                    firstName = null,
                    lastName = null,
                    country = null,
                    language = null,
                    homeCity = null,
                    phoneNumber = null,
                    gender = null,
                    dateOfBirth = null,
                )
            }
        assertTrue(exception.message.orEmpty().contains("email"))
    }

    @Test
    fun setUserProfileRejectsInvalidDateOfBirthFormat() {
        val exception =
            assertThrows(IllegalArgumentException::class.java) {
                implementation.validateUserProfileFields(
                    email = null,
                    firstName = null,
                    lastName = null,
                    country = null,
                    language = null,
                    homeCity = null,
                    phoneNumber = null,
                    gender = null,
                    dateOfBirth = "13/45/2020",
                )
            }
        assertTrue(exception.message.orEmpty().contains("dateOfBirth"))
    }

    @Test
    fun setUserProfileRejectsUnrecognizedGender() {
        val exception =
            assertThrows(IllegalArgumentException::class.java) {
                implementation.validateUserProfileFields(
                    email = null,
                    firstName = null,
                    lastName = null,
                    country = null,
                    language = null,
                    homeCity = null,
                    phoneNumber = null,
                    gender = "nonbinary",
                    dateOfBirth = null,
                )
            }
        val message = exception.message.orEmpty()
        assertTrue(message.contains("gender"))
        assertTrue(message.contains("male"))
        assertTrue(message.contains("prefer_not_to_say"))
    }
}
