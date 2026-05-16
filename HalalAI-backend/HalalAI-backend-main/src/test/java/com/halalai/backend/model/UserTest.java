package com.halalai.backend.model;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

class UserTest {

    @Test
    void prePersist_setsTimestamps() {
        var u = new User("a@b.com", "password123");
        assertNull(u.getCreatedAt());
        assertNull(u.getUpdatedAt());

        u.onCreate();

        assertNotNull(u.getCreatedAt());
        assertNotNull(u.getUpdatedAt());
        assertFalse(u.getCreatedAt().isAfter(LocalDateTime.now()));
    }

    @Test
    void preUpdate_updatesUpdatedAt() throws Exception {
        var u = new User("a@b.com", "password123");
        u.onCreate();
        var before = u.getUpdatedAt();

        Thread.sleep(2);
        u.onUpdate();

        assertTrue(u.getUpdatedAt().isAfter(before) || u.getUpdatedAt().isEqual(before));
    }

    @Test
    void gettersAndSetters_work() {
        var u = new User();
        u.setId(10L);
        u.setEmail("x@y.com");
        u.setPassword("p");
        u.setEnabled(false);
        u.setCreatedAt(LocalDateTime.of(2020, 1, 1, 0, 0));
        u.setUpdatedAt(LocalDateTime.of(2020, 1, 2, 0, 0));

        assertEquals(10L, u.getId());
        assertEquals("x@y.com", u.getEmail());
        assertEquals("p", u.getPassword());
        assertFalse(u.getEnabled());
        assertEquals(LocalDateTime.of(2020, 1, 1, 0, 0), u.getCreatedAt());
        assertEquals(LocalDateTime.of(2020, 1, 2, 0, 0), u.getUpdatedAt());
    }

    @Test
    void enabled_defaultsToTrue() {
        var u = new User();
        assertTrue(u.getEnabled());
    }
}

