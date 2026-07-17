package com.demo.controller;

import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class AppController {

    @GetMapping("/hello")
    public Map<String, String> hello() {
        return Map.of(
            "message", "Hello from Java CI/CD App!",
            "version", "1.0.0",
            "timestamp", LocalDateTime.now().toString()
        );
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of(
            "status", "UP",
            "service", "java-cicd-app"
        );
    }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of(
            "app", "Java CI/CD Demo",
            "author", "Vijay",
            "javaVersion", System.getProperty("java.version"),
            "timestamp", LocalDateTime.now().toString()
        );
    }

    @PostMapping("/echo")
    public Map<String, String> echo(@RequestBody Map<String, String> body) {
        return Map.of(
            "echo", body.getOrDefault("message", "no message"),
            "timestamp", LocalDateTime.now().toString()
        );
    }
}
