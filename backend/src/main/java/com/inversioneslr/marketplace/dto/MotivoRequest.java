package com.inversioneslr.marketplace.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// Motivo de una cancelación o de un rechazo
public record MotivoRequest(
        @NotBlank @Size(max = 500) String motivo
) {
}
