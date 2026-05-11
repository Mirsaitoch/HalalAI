package com.halalai.backend.security;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class JwtAuthenticationFilterTest {

    @Mock
    private JwtTokenProvider tokenProvider;

    @Mock
    private UserDetailsService userDetailsService;

    @Mock
    private FilterChain filterChain;

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void noAuthorizationHeader_doesNotAuthenticate_andContinuesChain() throws Exception {
        var sut = new JwtAuthenticationFilter(tokenProvider, userDetailsService);
        var req = new MockHttpServletRequest();
        var res = new MockHttpServletResponse();

        sut.doFilter(req, res, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(filterChain).doFilter(req, res);
        verifyNoInteractions(tokenProvider, userDetailsService);
    }

    @Test
    void bearerToken_valid_setsAuthentication() throws Exception {
        var sut = new JwtAuthenticationFilter(tokenProvider, userDetailsService);
        var req = new MockHttpServletRequest();
        req.addHeader("Authorization", "Bearer token123");
        var res = new MockHttpServletResponse();

        when(tokenProvider.getUsernameFromToken("token123")).thenReturn("a@b.com");
        UserDetails details = User.builder()
                .username("a@b.com")
                .password("x")
                .authorities("ROLE_USER")
                .build();
        when(userDetailsService.loadUserByUsername("a@b.com")).thenReturn(details);
        when(tokenProvider.validateToken("token123", details)).thenReturn(true);

        sut.doFilter(req, res, filterChain);

        var auth = SecurityContextHolder.getContext().getAuthentication();
        assertNotNull(auth);
        assertEquals("a@b.com", auth.getName());
        verify(filterChain).doFilter(req, res);
    }

    @Test
    void bearerToken_invalid_doesNotSetAuthentication() throws Exception {
        var sut = new JwtAuthenticationFilter(tokenProvider, userDetailsService);
        var req = new MockHttpServletRequest();
        req.addHeader("Authorization", "bearer token123");
        var res = new MockHttpServletResponse();

        when(tokenProvider.getUsernameFromToken("token123")).thenReturn("a@b.com");
        UserDetails details = User.builder().username("a@b.com").password("x").authorities("ROLE_USER").build();
        when(userDetailsService.loadUserByUsername("a@b.com")).thenReturn(details);
        when(tokenProvider.validateToken("token123", details)).thenReturn(false);

        sut.doFilter(req, res, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(filterChain).doFilter(req, res);
    }

    @Test
    void tokenProviderThrows_doesNotBreakChain() throws Exception {
        var sut = new JwtAuthenticationFilter(tokenProvider, userDetailsService);
        var req = new MockHttpServletRequest();
        req.addHeader("Authorization", "Bearer token123");
        var res = new MockHttpServletResponse();

        when(tokenProvider.getUsernameFromToken("token123")).thenThrow(new RuntimeException("bad token"));

        sut.doFilter(req, res, filterChain);

        assertNull(SecurityContextHolder.getContext().getAuthentication());
        verify(filterChain).doFilter(req, res);
    }
}

