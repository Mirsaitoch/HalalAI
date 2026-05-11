package com.halalai.backend.service;

import com.halalai.backend.model.User;
import com.halalai.backend.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserDetailsServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserDetailsServiceImpl sut;

    @Test
    void loadUserByUsername_returnsUserDetails_whenFoundAndEnabled() {
        var u = new User();
        u.setEmail("a@b.com");
        u.setPassword("enc");
        u.setEnabled(true);

        when(userRepository.findByEmail("a@b.com")).thenReturn(Optional.of(u));

        var details = sut.loadUserByUsername("a@b.com");

        assertEquals("a@b.com", details.getUsername());
        assertEquals("enc", details.getPassword());
        assertTrue(details.isEnabled());
        assertTrue(details.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_USER")));
    }

    @Test
    void loadUserByUsername_returnsDisabledUserDetails_whenUserDisabled() {
        var u = new User();
        u.setEmail("a@b.com");
        u.setPassword("enc");
        u.setEnabled(false);

        when(userRepository.findByEmail("a@b.com")).thenReturn(Optional.of(u));

        var details = sut.loadUserByUsername("a@b.com");

        assertFalse(details.isEnabled());
    }

    @Test
    void loadUserByUsername_throwsUsernameNotFound_whenMissing() {
        when(userRepository.findByEmail("missing@b.com")).thenReturn(Optional.empty());

        var ex = assertThrows(UsernameNotFoundException.class, () -> sut.loadUserByUsername("missing@b.com"));
        assertTrue(ex.getMessage().contains("missing@b.com"));
    }
}

