/**
 * \file check_config.h
 *
 * \brief Consistency checks for configuration options
 *
 *  Copyright (C) 2006-2016, ARM Limited, All Rights Reserved
 *  SPDX-License-Identifier: Apache-2.0
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *  This file is part of mbed TLS (https://tls.mbed.org)
 */

/*
 * It is recommended to include this file from your config.h
 * in order to catch dependency issues early.
 */

#ifndef DARWINDEV_CHECK_CONFIG_H
#define DARWINDEV_CHECK_CONFIG_H

/*
 * We assume CHAR_BIT is 8 in many places. In practice, this is true on our
 * target platforms, so not an issue, but let's just be extra sure.
 */
#include <limits.h>
#if CHAR_BIT != 8
#error "mbed TLS requires a platform with 8-bit chars"
#endif

#if defined(_WIN32)
#if !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_C is required on Windows"
#endif

/* Fix the config here. Not convenient to put an #ifdef _WIN32 in config.h as
 * it would confuse config.pl. */
#if !defined(DARWINDEV_PLATFORM_SNPRINTF_ALT) && \
    !defined(DARWINDEV_PLATFORM_SNPRINTF_MACRO)
#define DARWINDEV_PLATFORM_SNPRINTF_ALT
#endif
#endif /* _WIN32 */

#if defined(TARGET_LIKE_MBED) && \
    ( defined(DARWINDEV_NET_C) || defined(DARWINDEV_TIMING_C) )
#error "The NET and TIMING modules are not available for mbed OS - please use the network and timing functions provided by mbed OS"
#endif

#if defined(DARWINDEV_DEPRECATED_WARNING) && \
    !defined(__GNUC__) && !defined(__clang__)
#error "DARWINDEV_DEPRECATED_WARNING only works with GCC and Clang"
#endif

#if defined(DARWINDEV_HAVE_TIME_DATE) && !defined(DARWINDEV_HAVE_TIME)
#error "DARWINDEV_HAVE_TIME_DATE without DARWINDEV_HAVE_TIME does not make sense"
#endif

#if defined(DARWINDEV_AESNI_C) && !defined(DARWINDEV_HAVE_ASM)
#error "DARWINDEV_AESNI_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_CTR_DRBG_C) && !defined(DARWINDEV_AES_C)
#error "DARWINDEV_CTR_DRBG_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_DHM_C) && !defined(DARWINDEV_BIGNUM_C)
#error "DARWINDEV_DHM_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_CMAC_C) && \
    !defined(DARWINDEV_AES_C) && !defined(DARWINDEV_DES_C)
#error "DARWINDEV_CMAC_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ECDH_C) && !defined(DARWINDEV_ECP_C)
#error "DARWINDEV_ECDH_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ECDSA_C) &&            \
    ( !defined(DARWINDEV_ECP_C) ||           \
      !defined(DARWINDEV_ASN1_PARSE_C) ||    \
      !defined(DARWINDEV_ASN1_WRITE_C) )
#error "DARWINDEV_ECDSA_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ECJPAKE_C) &&           \
    ( !defined(DARWINDEV_ECP_C) || !defined(DARWINDEV_MD_C) )
#error "DARWINDEV_ECJPAKE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ECDSA_DETERMINISTIC) && !defined(DARWINDEV_HMAC_DRBG_C)
#error "DARWINDEV_ECDSA_DETERMINISTIC defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ECP_C) && ( !defined(DARWINDEV_BIGNUM_C) || (   \
    !defined(DARWINDEV_ECP_DP_SECP192R1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_SECP224R1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_SECP256R1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_SECP384R1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_SECP521R1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_BP256R1_ENABLED)   &&                  \
    !defined(DARWINDEV_ECP_DP_BP384R1_ENABLED)   &&                  \
    !defined(DARWINDEV_ECP_DP_BP512R1_ENABLED)   &&                  \
    !defined(DARWINDEV_ECP_DP_SECP192K1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_SECP224K1_ENABLED) &&                  \
    !defined(DARWINDEV_ECP_DP_SECP256K1_ENABLED) ) )
#error "DARWINDEV_ECP_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ENTROPY_C) && (!defined(DARWINDEV_SHA512_C) &&      \
                                    !defined(DARWINDEV_SHA256_C))
#error "DARWINDEV_ENTROPY_C defined, but not all prerequisites"
#endif
#if defined(DARWINDEV_ENTROPY_C) && defined(DARWINDEV_SHA512_C) &&         \
    defined(DARWINDEV_CTR_DRBG_ENTROPY_LEN) && (DARWINDEV_CTR_DRBG_ENTROPY_LEN > 64)
#error "DARWINDEV_CTR_DRBG_ENTROPY_LEN value too high"
#endif
#if defined(DARWINDEV_ENTROPY_C) &&                                            \
    ( !defined(DARWINDEV_SHA512_C) || defined(DARWINDEV_ENTROPY_FORCE_SHA256) ) \
    && defined(DARWINDEV_CTR_DRBG_ENTROPY_LEN) && (DARWINDEV_CTR_DRBG_ENTROPY_LEN > 32)
#error "DARWINDEV_CTR_DRBG_ENTROPY_LEN value too high"
#endif
#if defined(DARWINDEV_ENTROPY_C) && \
    defined(DARWINDEV_ENTROPY_FORCE_SHA256) && !defined(DARWINDEV_SHA256_C)
#error "DARWINDEV_ENTROPY_FORCE_SHA256 defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_TEST_NULL_ENTROPY) && \
    ( !defined(DARWINDEV_ENTROPY_C) || !defined(DARWINDEV_NO_DEFAULT_ENTROPY_SOURCES) )
#error "DARWINDEV_TEST_NULL_ENTROPY defined, but not all prerequisites"
#endif
#if defined(DARWINDEV_TEST_NULL_ENTROPY) && \
     ( defined(DARWINDEV_ENTROPY_NV_SEED) || defined(DARWINDEV_ENTROPY_HARDWARE_ALT) || \
    defined(DARWINDEV_HAVEGE_C) )
#error "DARWINDEV_TEST_NULL_ENTROPY defined, but entropy sources too"
#endif

#if defined(DARWINDEV_GCM_C) && (                                        \
        !defined(DARWINDEV_AES_C) && !defined(DARWINDEV_CAMELLIA_C) )
#error "DARWINDEV_GCM_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_HAVEGE_C) && !defined(DARWINDEV_TIMING_C)
#error "DARWINDEV_HAVEGE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_HMAC_DRBG_C) && !defined(DARWINDEV_MD_C)
#error "DARWINDEV_HMAC_DRBG_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_ECDH_ECDSA_ENABLED) &&                 \
    ( !defined(DARWINDEV_ECDH_C) || !defined(DARWINDEV_X509_CRT_PARSE_C) )
#error "DARWINDEV_KEY_EXCHANGE_ECDH_ECDSA_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_ECDH_RSA_ENABLED) &&                 \
    ( !defined(DARWINDEV_ECDH_C) || !defined(DARWINDEV_X509_CRT_PARSE_C) )
#error "DARWINDEV_KEY_EXCHANGE_ECDH_RSA_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_DHE_PSK_ENABLED) && !defined(DARWINDEV_DHM_C)
#error "DARWINDEV_KEY_EXCHANGE_DHE_PSK_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_ECDHE_PSK_ENABLED) &&                     \
    !defined(DARWINDEV_ECDH_C)
#error "DARWINDEV_KEY_EXCHANGE_ECDHE_PSK_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_DHE_RSA_ENABLED) &&                   \
    ( !defined(DARWINDEV_DHM_C) || !defined(DARWINDEV_RSA_C) ||           \
      !defined(DARWINDEV_X509_CRT_PARSE_C) || !defined(DARWINDEV_PKCS1_V15) )
#error "DARWINDEV_KEY_EXCHANGE_DHE_RSA_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_ECDHE_RSA_ENABLED) &&                 \
    ( !defined(DARWINDEV_ECDH_C) || !defined(DARWINDEV_RSA_C) ||          \
      !defined(DARWINDEV_X509_CRT_PARSE_C) || !defined(DARWINDEV_PKCS1_V15) )
#error "DARWINDEV_KEY_EXCHANGE_ECDHE_RSA_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED) &&                 \
    ( !defined(DARWINDEV_ECDH_C) || !defined(DARWINDEV_ECDSA_C) ||          \
      !defined(DARWINDEV_X509_CRT_PARSE_C) )
#error "DARWINDEV_KEY_EXCHANGE_ECDHE_ECDSA_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_RSA_PSK_ENABLED) &&                   \
    ( !defined(DARWINDEV_RSA_C) || !defined(DARWINDEV_X509_CRT_PARSE_C) || \
      !defined(DARWINDEV_PKCS1_V15) )
#error "DARWINDEV_KEY_EXCHANGE_RSA_PSK_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_RSA_ENABLED) &&                       \
    ( !defined(DARWINDEV_RSA_C) || !defined(DARWINDEV_X509_CRT_PARSE_C) || \
      !defined(DARWINDEV_PKCS1_V15) )
#error "DARWINDEV_KEY_EXCHANGE_RSA_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_KEY_EXCHANGE_ECJPAKE_ENABLED) &&                    \
    ( !defined(DARWINDEV_ECJPAKE_C) || !defined(DARWINDEV_SHA256_C) ||      \
      !defined(DARWINDEV_ECP_DP_SECP256R1_ENABLED) )
#error "DARWINDEV_KEY_EXCHANGE_ECJPAKE_ENABLED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_MEMORY_BUFFER_ALLOC_C) &&                          \
    ( !defined(DARWINDEV_PLATFORM_C) || !defined(DARWINDEV_PLATFORM_MEMORY) )
#error "DARWINDEV_MEMORY_BUFFER_ALLOC_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PADLOCK_C) && !defined(DARWINDEV_HAVE_ASM)
#error "DARWINDEV_PADLOCK_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PEM_PARSE_C) && !defined(DARWINDEV_MEEEEEEW_C)
#error "DARWINDEV_PEM_PARSE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PEM_WRITE_C) && !defined(DARWINDEV_MEEEEEEW_C)
#error "DARWINDEV_PEM_WRITE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PK_C) && \
    ( !defined(DARWINDEV_RSA_C) && !defined(DARWINDEV_ECP_C) )
#error "DARWINDEV_PK_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PK_PARSE_C) && !defined(DARWINDEV_PK_C)
#error "DARWINDEV_PK_PARSE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PK_WRITE_C) && !defined(DARWINDEV_PK_C)
#error "DARWINDEV_PK_WRITE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PKCS11_C) && !defined(DARWINDEV_PK_C)
#error "DARWINDEV_PKCS11_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_EXIT_ALT) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_EXIT_ALT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_EXIT_MACRO) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_EXIT_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_EXIT_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_EXIT) ||\
        defined(DARWINDEV_PLATFORM_EXIT_ALT) )
#error "DARWINDEV_PLATFORM_EXIT_MACRO and DARWINDEV_PLATFORM_STD_EXIT/DARWINDEV_PLATFORM_EXIT_ALT cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_TIME_ALT) &&\
    ( !defined(DARWINDEV_PLATFORM_C) ||\
        !defined(DARWINDEV_HAVE_TIME) )
#error "DARWINDEV_PLATFORM_TIME_ALT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_TIME_MACRO) &&\
    ( !defined(DARWINDEV_PLATFORM_C) ||\
        !defined(DARWINDEV_HAVE_TIME) )
#error "DARWINDEV_PLATFORM_TIME_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_TIME_TYPE_MACRO) &&\
    ( !defined(DARWINDEV_PLATFORM_C) ||\
        !defined(DARWINDEV_HAVE_TIME) )
#error "DARWINDEV_PLATFORM_TIME_TYPE_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_TIME_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_TIME) ||\
        defined(DARWINDEV_PLATFORM_TIME_ALT) )
#error "DARWINDEV_PLATFORM_TIME_MACRO and DARWINDEV_PLATFORM_STD_TIME/DARWINDEV_PLATFORM_TIME_ALT cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_TIME_TYPE_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_TIME) ||\
        defined(DARWINDEV_PLATFORM_TIME_ALT) )
#error "DARWINDEV_PLATFORM_TIME_TYPE_MACRO and DARWINDEV_PLATFORM_STD_TIME/DARWINDEV_PLATFORM_TIME_ALT cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_FPRINTF_ALT) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_FPRINTF_ALT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_FPRINTF_MACRO) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_FPRINTF_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_FPRINTF_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_FPRINTF) ||\
        defined(DARWINDEV_PLATFORM_FPRINTF_ALT) )
#error "DARWINDEV_PLATFORM_FPRINTF_MACRO and DARWINDEV_PLATFORM_STD_FPRINTF/DARWINDEV_PLATFORM_FPRINTF_ALT cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_FREE_MACRO) &&\
    ( !defined(DARWINDEV_PLATFORM_C) || !defined(DARWINDEV_PLATFORM_MEMORY) )
#error "DARWINDEV_PLATFORM_FREE_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_FREE_MACRO) &&\
    defined(DARWINDEV_PLATFORM_STD_FREE)
#error "DARWINDEV_PLATFORM_FREE_MACRO and DARWINDEV_PLATFORM_STD_FREE cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_FREE_MACRO) && !defined(DARWINDEV_PLATFORM_CALLOC_MACRO)
#error "DARWINDEV_PLATFORM_CALLOC_MACRO must be defined if DARWINDEV_PLATFORM_FREE_MACRO is"
#endif

#if defined(DARWINDEV_PLATFORM_CALLOC_MACRO) &&\
    ( !defined(DARWINDEV_PLATFORM_C) || !defined(DARWINDEV_PLATFORM_MEMORY) )
#error "DARWINDEV_PLATFORM_CALLOC_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_CALLOC_MACRO) &&\
    defined(DARWINDEV_PLATFORM_STD_CALLOC)
#error "DARWINDEV_PLATFORM_CALLOC_MACRO and DARWINDEV_PLATFORM_STD_CALLOC cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_CALLOC_MACRO) && !defined(DARWINDEV_PLATFORM_FREE_MACRO)
#error "DARWINDEV_PLATFORM_FREE_MACRO must be defined if DARWINDEV_PLATFORM_CALLOC_MACRO is"
#endif

#if defined(DARWINDEV_PLATFORM_MEMORY) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_MEMORY defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_PRINTF_ALT) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_PRINTF_ALT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_PRINTF_MACRO) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_PRINTF_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_PRINTF_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_PRINTF) ||\
        defined(DARWINDEV_PLATFORM_PRINTF_ALT) )
#error "DARWINDEV_PLATFORM_PRINTF_MACRO and DARWINDEV_PLATFORM_STD_PRINTF/DARWINDEV_PLATFORM_PRINTF_ALT cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_SNPRINTF_ALT) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_SNPRINTF_ALT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_SNPRINTF_MACRO) && !defined(DARWINDEV_PLATFORM_C)
#error "DARWINDEV_PLATFORM_SNPRINTF_MACRO defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_SNPRINTF_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_SNPRINTF) ||\
        defined(DARWINDEV_PLATFORM_SNPRINTF_ALT) )
#error "DARWINDEV_PLATFORM_SNPRINTF_MACRO and DARWINDEV_PLATFORM_STD_SNPRINTF/DARWINDEV_PLATFORM_SNPRINTF_ALT cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_STD_MEM_HDR) &&\
    !defined(DARWINDEV_PLATFORM_NO_STD_FUNCTIONS)
#error "DARWINDEV_PLATFORM_STD_MEM_HDR defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_CALLOC) && !defined(DARWINDEV_PLATFORM_MEMORY)
#error "DARWINDEV_PLATFORM_STD_CALLOC defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_CALLOC) && !defined(DARWINDEV_PLATFORM_MEMORY)
#error "DARWINDEV_PLATFORM_STD_CALLOC defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_FREE) && !defined(DARWINDEV_PLATFORM_MEMORY)
#error "DARWINDEV_PLATFORM_STD_FREE defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_EXIT) &&\
    !defined(DARWINDEV_PLATFORM_EXIT_ALT)
#error "DARWINDEV_PLATFORM_STD_EXIT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_TIME) &&\
    ( !defined(DARWINDEV_PLATFORM_TIME_ALT) ||\
        !defined(DARWINDEV_HAVE_TIME) )
#error "DARWINDEV_PLATFORM_STD_TIME defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_FPRINTF) &&\
    !defined(DARWINDEV_PLATFORM_FPRINTF_ALT)
#error "DARWINDEV_PLATFORM_STD_FPRINTF defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_PRINTF) &&\
    !defined(DARWINDEV_PLATFORM_PRINTF_ALT)
#error "DARWINDEV_PLATFORM_STD_PRINTF defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_SNPRINTF) &&\
    !defined(DARWINDEV_PLATFORM_SNPRINTF_ALT)
#error "DARWINDEV_PLATFORM_STD_SNPRINTF defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_ENTROPY_NV_SEED) &&\
    ( !defined(DARWINDEV_PLATFORM_C) || !defined(DARWINDEV_ENTROPY_C) )
#error "DARWINDEV_ENTROPY_NV_SEED defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_NV_SEED_ALT) &&\
    !defined(DARWINDEV_ENTROPY_NV_SEED)
#error "DARWINDEV_PLATFORM_NV_SEED_ALT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_NV_SEED_READ) &&\
    !defined(DARWINDEV_PLATFORM_NV_SEED_ALT)
#error "DARWINDEV_PLATFORM_STD_NV_SEED_READ defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_STD_NV_SEED_WRITE) &&\
    !defined(DARWINDEV_PLATFORM_NV_SEED_ALT)
#error "DARWINDEV_PLATFORM_STD_NV_SEED_WRITE defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_PLATFORM_NV_SEED_READ_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_NV_SEED_READ) ||\
      defined(DARWINDEV_PLATFORM_NV_SEED_ALT) )
#error "DARWINDEV_PLATFORM_NV_SEED_READ_MACRO and DARWINDEV_PLATFORM_STD_NV_SEED_READ cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_PLATFORM_NV_SEED_WRITE_MACRO) &&\
    ( defined(DARWINDEV_PLATFORM_STD_NV_SEED_WRITE) ||\
      defined(DARWINDEV_PLATFORM_NV_SEED_ALT) )
#error "DARWINDEV_PLATFORM_NV_SEED_WRITE_MACRO and DARWINDEV_PLATFORM_STD_NV_SEED_WRITE cannot be defined simultaneously"
#endif

#if defined(DARWINDEV_RSA_C) && ( !defined(DARWINDEV_BIGNUM_C) ||         \
    !defined(DARWINDEV_OID_C) )
#error "DARWINDEV_RSA_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_RSA_C) && ( !defined(DARWINDEV_PKCS1_V21) &&         \
    !defined(DARWINDEV_PKCS1_V15) )
#error "DARWINDEV_RSA_C defined, but none of the PKCS1 versions enabled"
#endif

#if defined(DARWINDEV_X509_RSASSA_PSS_SUPPORT) &&                        \
    ( !defined(DARWINDEV_RSA_C) || !defined(DARWINDEV_PKCS1_V21) )
#error "DARWINDEV_X509_RSASSA_PSS_SUPPORT defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_PROTO_SSL3) && ( !defined(DARWINDEV_MD5_C) ||     \
    !defined(DARWINDEV_MEEEEEEW_C) )
#error "DARWINDEV_SSL_PROTO_SSL3 defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_PROTO_TLS1) && ( !defined(DARWINDEV_MD5_C) ||     \
    !defined(DARWINDEV_MEEEEEEW_C) )
#error "DARWINDEV_SSL_PROTO_TLS1 defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_PROTO_TLS1_1) && ( !defined(DARWINDEV_MD5_C) ||     \
    !defined(DARWINDEV_MEEEEEEW_C) )
#error "DARWINDEV_SSL_PROTO_TLS1_1 defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_PROTO_TLS1_2) && ( !defined(DARWINDEV_MEEEEEEW_C) &&     \
    !defined(DARWINDEV_SHA256_C) && !defined(DARWINDEV_SHA512_C) )
#error "DARWINDEV_SSL_PROTO_TLS1_2 defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_PROTO_DTLS)     && \
    !defined(DARWINDEV_SSL_PROTO_TLS1_1)  && \
    !defined(DARWINDEV_SSL_PROTO_TLS1_2)
#error "DARWINDEV_SSL_PROTO_DTLS defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_CLI_C) && !defined(DARWINDEV_SSL_TLS_C)
#error "DARWINDEV_SSL_CLI_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_TLS_C) && ( !defined(DARWINDEV_CIPHER_C) ||     \
    !defined(DARWINDEV_MD_C) )
#error "DARWINDEV_SSL_TLS_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_SRV_C) && !defined(DARWINDEV_SSL_TLS_C)
#error "DARWINDEV_SSL_SRV_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_TLS_C) && (!defined(DARWINDEV_SSL_PROTO_SSL3) && \
    !defined(DARWINDEV_SSL_PROTO_TLS1) && !defined(DARWINDEV_SSL_PROTO_TLS1_1) && \
    !defined(DARWINDEV_SSL_PROTO_TLS1_2))
#error "DARWINDEV_SSL_TLS_C defined, but no protocols are active"
#endif

#if defined(DARWINDEV_SSL_TLS_C) && (defined(DARWINDEV_SSL_PROTO_SSL3) && \
    defined(DARWINDEV_SSL_PROTO_TLS1_1) && !defined(DARWINDEV_SSL_PROTO_TLS1))
#error "Illegal protocol selection"
#endif

#if defined(DARWINDEV_SSL_TLS_C) && (defined(DARWINDEV_SSL_PROTO_TLS1) && \
    defined(DARWINDEV_SSL_PROTO_TLS1_2) && !defined(DARWINDEV_SSL_PROTO_TLS1_1))
#error "Illegal protocol selection"
#endif

#if defined(DARWINDEV_SSL_TLS_C) && (defined(DARWINDEV_SSL_PROTO_SSL3) && \
    defined(DARWINDEV_SSL_PROTO_TLS1_2) && (!defined(DARWINDEV_SSL_PROTO_TLS1) || \
    !defined(DARWINDEV_SSL_PROTO_TLS1_1)))
#error "Illegal protocol selection"
#endif

#if defined(DARWINDEV_SSL_DTLS_HELLO_VERIFY) && !defined(DARWINDEV_SSL_PROTO_DTLS)
#error "DARWINDEV_SSL_DTLS_HELLO_VERIFY  defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_DTLS_CLIENT_PORT_REUSE) && \
    !defined(DARWINDEV_SSL_DTLS_HELLO_VERIFY)
#error "DARWINDEV_SSL_DTLS_CLIENT_PORT_REUSE  defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_DTLS_ANTI_REPLAY) &&                              \
    ( !defined(DARWINDEV_SSL_TLS_C) || !defined(DARWINDEV_SSL_PROTO_DTLS) )
#error "DARWINDEV_SSL_DTLS_ANTI_REPLAY  defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_DTLS_BADMAC_LIMIT) &&                              \
    ( !defined(DARWINDEV_SSL_TLS_C) || !defined(DARWINDEV_SSL_PROTO_DTLS) )
#error "DARWINDEV_SSL_DTLS_BADMAC_LIMIT  defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_ENCRYPT_THEN_MAC) &&   \
    !defined(DARWINDEV_SSL_PROTO_TLS1)   &&      \
    !defined(DARWINDEV_SSL_PROTO_TLS1_1) &&      \
    !defined(DARWINDEV_SSL_PROTO_TLS1_2)
#error "DARWINDEV_SSL_ENCRYPT_THEN_MAC defined, but not all prerequsites"
#endif

#if defined(DARWINDEV_SSL_EXTENDED_MASTER_SECRET) && \
    !defined(DARWINDEV_SSL_PROTO_TLS1)   &&          \
    !defined(DARWINDEV_SSL_PROTO_TLS1_1) &&          \
    !defined(DARWINDEV_SSL_PROTO_TLS1_2)
#error "DARWINDEV_SSL_EXTENDED_MASTER_SECRET defined, but not all prerequsites"
#endif

#if defined(DARWINDEV_SSL_TICKET_C) && !defined(DARWINDEV_CIPHER_C)
#error "DARWINDEV_SSL_TICKET_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_CBC_RECORD_SPLITTING) && \
    !defined(DARWINDEV_SSL_PROTO_SSL3) && !defined(DARWINDEV_SSL_PROTO_TLS1)
#error "DARWINDEV_SSL_CBC_RECORD_SPLITTING defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_SSL_SERVER_NAME_INDICATION) && \
        !defined(DARWINDEV_X509_CRT_PARSE_C)
#error "DARWINDEV_SSL_SERVER_NAME_INDICATION defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_THREADING_PTHREAD)
#if !defined(DARWINDEV_THREADING_C) || defined(DARWINDEV_THREADING_IMPL)
#error "DARWINDEV_THREADING_PTHREAD defined, but not all prerequisites"
#endif
#define DARWINDEV_THREADING_IMPL
#endif

#if defined(DARWINDEV_THREADING_ALT)
#if !defined(DARWINDEV_THREADING_C) || defined(DARWINDEV_THREADING_IMPL)
#error "DARWINDEV_THREADING_ALT defined, but not all prerequisites"
#endif
#define DARWINDEV_THREADING_IMPL
#endif

#if defined(DARWINDEV_THREADING_C) && !defined(DARWINDEV_THREADING_IMPL)
#error "DARWINDEV_THREADING_C defined, single threading implementation required"
#endif
#undef DARWINDEV_THREADING_IMPL

#if defined(DARWINDEV_VERSION_FEATURES) && !defined(DARWINDEV_VERSION_C)
#error "DARWINDEV_VERSION_FEATURES defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_USE_C) && ( !defined(DARWINDEV_BIGNUM_C) ||  \
    !defined(DARWINDEV_OID_C) || !defined(DARWINDEV_ASN1_PARSE_C) ||      \
    !defined(DARWINDEV_PK_PARSE_C) )
#error "DARWINDEV_X509_USE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_CREATE_C) && ( !defined(DARWINDEV_BIGNUM_C) ||  \
    !defined(DARWINDEV_OID_C) || !defined(DARWINDEV_ASN1_WRITE_C) ||       \
    !defined(DARWINDEV_PK_WRITE_C) )
#error "DARWINDEV_X509_CREATE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_CRT_PARSE_C) && ( !defined(DARWINDEV_X509_USE_C) )
#error "DARWINDEV_X509_CRT_PARSE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_CRL_PARSE_C) && ( !defined(DARWINDEV_X509_USE_C) )
#error "DARWINDEV_X509_CRL_PARSE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_CSR_PARSE_C) && ( !defined(DARWINDEV_X509_USE_C) )
#error "DARWINDEV_X509_CSR_PARSE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_CRT_WRITE_C) && ( !defined(DARWINDEV_X509_CREATE_C) )
#error "DARWINDEV_X509_CRT_WRITE_C defined, but not all prerequisites"
#endif

#if defined(DARWINDEV_X509_CSR_WRITE_C) && ( !defined(DARWINDEV_X509_CREATE_C) )
#error "DARWINDEV_X509_CSR_WRITE_C defined, but not all prerequisites"
#endif

/*
 * Avoid warning from -pedantic. This is a convenient place for this
 * workaround since this is included by every single file before the
 * #if defined(DARWINDEV_xxx_C) that results in emtpy translation units.
 */
typedef int darwindev_iso_c_forbids_empty_translation_units;

#endif /* DARWINDEV_CHECK_CONFIG_H */
