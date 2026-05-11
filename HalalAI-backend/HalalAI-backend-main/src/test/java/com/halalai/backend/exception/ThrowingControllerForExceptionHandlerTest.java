package com.halalai.backend.exception;

import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

@RestController
@RequestMapping("/test")
class ThrowingControllerForExceptionHandlerTest {

    @PostMapping(value = "/validate", consumes = MediaType.APPLICATION_JSON_VALUE)
    public String validate(@Valid @RequestBody ValidateDto dto) {
        return "ok";
    }

    @GetMapping("/constraint")
    public String constraint() {
        @SuppressWarnings("unchecked")
        var violation = (jakarta.validation.ConstraintViolation<Object>) mock(jakarta.validation.ConstraintViolation.class);
        var path = mock(jakarta.validation.Path.class);
        when(path.toString()).thenReturn("someField");
        when(violation.getPropertyPath()).thenReturn(path);
        when(violation.getMessage()).thenReturn("must not be blank");
        throw new ConstraintViolationException(java.util.Set.of(violation));
    }

    @GetMapping("/illegal-arg")
    public String illegalArg() {
        throw new IllegalArgumentException("bad input");
    }

    @GetMapping("/bad-credentials")
    public String badCredentials() {
        throw new BadCredentialsException("bad");
    }

    @GetMapping("/username-not-found")
    public String usernameNotFound() {
        throw new UsernameNotFoundException("nope");
    }

    @GetMapping("/runtime")
    public String runtime() {
        throw new RuntimeException("boom");
    }

    @GetMapping("/unknown")
    public String unknown() throws Exception {
        throw new Exception("checked");
    }

    record ValidateDto(@NotBlank(message = "value не может быть пустым") String value) {}
}

