#include <eosio/eosio.hpp>

using namespace eosio;

CONTRACT noopcontract : public contract {
public:
    using contract::contract;

    ACTION noop() {
        // Intentionally left blank - no operation
    }
};
