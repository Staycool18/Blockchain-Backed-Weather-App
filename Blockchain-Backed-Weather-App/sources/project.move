module WeatherApp::WeatherOracle {
    use std::string::String;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event;

    /// Struct to store weather data for a specific location
    struct WeatherData has key, store {
        temperature: u64,        // Temperature in Celsius
        humidity: u64,           // Humidity percentage
        last_updated: u64,       // Timestamp of last update
        location: String,        // Location identifier
        oracle_address: address  // Address of the oracle updating data
    }

    /// Event emitted when weather data is updated
    struct WeatherUpdateEvent has drop, store {
        location: String,
        temperature: u64,
        humidity: u64,
        timestamp: u64
    }

    /// Struct to hold the event handle for weather updates
    struct WeatherOracleState has key {
        weather_update_events: event::EventHandle<WeatherUpdateEvent>,
    }

    /// Initialize weather data and event handle for a new location
    public fun initialize_weather_location(
        oracle: &signer,
        location: String,
        initial_temp: u64,
        initial_humidity: u64
    ) {
        let oracle_addr = account::get_address(oracle);

        // Create and store WeatherData
        let weather_data = WeatherData {
            temperature: initial_temp,
            humidity: initial_humidity,
            last_updated: timestamp::now_seconds(),
            location,
            oracle_address: oracle_addr
        };
        move_to(oracle, weather_data);

        // Create and store WeatherOracleState with event handle
        let event_handle = event::new_event_handle<WeatherUpdateEvent>(oracle);
        let state = WeatherOracleState {
            weather_update_events: event_handle
        };
        move_to(oracle, state);
    }

    /// Update weather data and emit event
    public fun update_weather_data(
        oracle: &signer,
        new_temp: u64,
        new_humidity: u64
    ) acquires WeatherData, WeatherOracleState {
        let oracle_addr = account::get_address(oracle);

        // Borrow and update WeatherData
        let weather_data = borrow_global_mut<WeatherData>(oracle_addr);
        weather_data.temperature = new_temp;
        weather_data.humidity = new_humidity;
        weather_data.last_updated = timestamp::now_seconds();

        // Emit WeatherUpdateEvent
        let state = borrow_global_mut<WeatherOracleState>(oracle_addr);
        event::emit_event(
            &mut state.weather_update_events,
            WeatherUpdateEvent {
                location: weather_data.location.clone(),
                temperature: new_temp,
                humidity: new_humidity,
                timestamp: weather_data.last_updated
            }
        );
    }
}
