
#include "error/error_handler.hpp"
#include "log/logger.hpp"

namespace sl { namespace error {
    ErrorHandler::ErrorHandler(const std::string &logger, const std::string &severity) {
        logger_ptr_ = log::Logger::AddLogger(logger, severity);
    }
}}

