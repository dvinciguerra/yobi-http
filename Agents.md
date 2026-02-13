# Yobi HTTP Client - Technical Documentation

## Overview

Yobi (呼び) is a lightweight Ruby HTTP client designed for testing APIs from the command line. It provides a simple and efficient way to make HTTP requests with human-friendly output formatting, inspired by HTTPie.

**Key Features:**
- Simple command-line interface
- Support for all standard HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)
- JSON formatting and syntax highlighting
- Multiple authentication methods
- Customizable output formats
- Offline mode for request debugging
- Raw output mode for piping to other tools

## System Requirements

- Ruby >= 3.0.0
- RubyGems package manager

## Installation

### Install from RubyGems

The simplest way to install Yobi is through RubyGems:

```bash
gem install yobi-http
```

### Install from Source

Clone the repository and install locally:

```bash
git clone https://github.com/dvinciguerra/yobi-http.git
cd yobi-http
bundle install
bundle exec rake install
```

### Verify Installation

Check that Yobi is installed correctly:

```bash
yobi --version
```

## Usage

### Basic Syntax

```bash
yobi [METHOD] <url> [HEADER:VALUE] [key=value]
```

### HTTP Methods

Yobi supports all standard HTTP methods:

- **GET** - Retrieve resources (default method)
- **POST** - Create new resources
- **PUT** - Update existing resources
- **DELETE** - Remove resources
- **PATCH** - Partially update resources
- **HEAD** - Get resource headers only
- **OPTIONS** - Get available methods

### Basic Examples

#### Simple GET Request

```bash
yobi GET https://jsonplaceholder.typicode.com/posts/1
```

Or simply (GET is the default):

```bash
yobi https://jsonplaceholder.typicode.com/posts/1
```

#### POST Request with Data

```bash
yobi POST https://jsonplaceholder.typicode.com/posts title="foo" body="bar" userId=1
```

#### Request with Custom Headers

```bash
yobi GET https://jsonplaceholder.typicode.com/posts/1 Authorization:"Bearer <token>"
```

#### Using Localhost Shorthand

```bash
yobi :8080/api/items
# Expands to: http://localhost:8080/api/items
```

### Authentication

#### Basic Authentication

```bash
yobi -A basic -a username:password https://api.example.com/secure-data
```

#### Bearer Token Authentication

```bash
yobi -A bearer -a YOUR_TOKEN https://api.example.com/secure-data
```

Or use a header directly:

```bash
yobi GET https://api.example.com/secure-data Authorization:"Bearer YOUR_TOKEN"
```

### Command-Line Options

#### Output Control

**Print Format (`-p`, `--print`)**

Control what parts of the response to display:

- `H` - Print headers only
- `B` - Print body only
- `HB` - Print headers and body (default)

```bash
yobi --print B https://api.example.com/data
```

**Raw Output (`--raw`)**

Print raw response without formatting (useful for piping to other tools):

```bash
yobi --raw --print B POST https://httpbin.org/anything | jq '.headers["User-Agent"]'
```

#### Authentication Options

- `-a, --auth USER:PASS` - Specify authentication credentials
- `-A, --auth-type TYPE` - Specify authentication type (basic, bearer)

```bash
yobi -A basic -a user:pass https://api.example.com/secure
```

#### Debugging Options

**Verbose Mode (`-v`, `--verbose`)**

Print detailed request and response information:

```bash
yobi -v GET https://api.example.com/users
```

**Offline Mode (`--offline`)**

Prepare the request without sending it (useful for debugging):

```bash
yobi --offline POST https://api.example.com/users name=John age=30
```

**Debug Environment Variable**

Enable debug output with environment variable:

```bash
YOBI_DEBUG=1 yobi GET https://api.example.com/users
```

#### Other Options

- `-h, --help` - Display help message
- `--version` - Display version information

## Advanced Usage

### Combining Multiple Parameters

You can combine headers and data in a single request:

```bash
yobi POST https://api.example.com/users \
  name=John \
  email=john@example.com \
  Authorization:"Bearer token123" \
  Content-Type:"application/json"
```

### Working with Different Content Types

By default, Yobi uses `application/json`. Override with custom headers:

```bash
yobi POST https://api.example.com/form \
  username=john \
  password=secret \
  Content-Type:"application/x-www-form-urlencoded"
```

### Piping Output

Use raw mode to pipe output to other command-line tools:

```bash
# Extract specific fields with jq
yobi --raw --print B GET https://api.example.com/users | jq '.[0].name'

# Save response to file
yobi --raw --print B GET https://api.example.com/data > response.json

# Count lines in response
yobi --raw --print B GET https://api.example.com/logs | wc -l
```

## Development

### Setting Up Development Environment

1. Clone the repository:
```bash
git clone https://github.com/dvinciguerra/yobi-http.git
cd yobi-http
```

2. Install dependencies:
```bash
bin/setup
```

3. Run the interactive console:
```bash
bin/console
```

### Building the Gem

To build the gem locally:

```bash
bundle exec rake build
```

The gem file will be created in the `pkg/` directory.

### Installing Local Development Version

```bash
bundle exec rake install
```

### Running Tests

```bash
bundle exec rake test
```

### Code Quality

Check code style with RuboCop:

```bash
rubocop
```

### Release Process

1. Update version in `lib/yobi.rb`
2. Update `CHANGELOG.md`
3. Run tests and ensure they pass
4. Create release:
```bash
bundle exec rake release
```

This will:
- Create a git tag for the version
- Build and push the gem to RubyGems
- Push commits and tags to GitHub

## Project Structure

```
yobi-http/
├── exe/
│   └── yobi              # Main executable
├── lib/
│   ├── yobi.rb          # Core module and version
│   ├── yobi/
│   │   └── http.rb      # HTTP constants
│   └── views/           # Output templates
├── bin/
│   ├── setup            # Development setup script
│   └── console          # Interactive console
├── yobi.gemspec         # Gem specification
└── README.md            # User documentation
```

## Dependencies

- **tty-markdown (~> 0.7)** - Markdown rendering with syntax highlighting for formatted output

## Technical Details

### URL Resolution

Yobi intelligently resolves URLs:

- Full URLs: `https://api.example.com/path`
- Without protocol: `api.example.com/path` → `http://api.example.com/path`
- Localhost shorthand: `:8080/path` → `http://localhost:8080/path`

### Request Processing

1. Parse command-line arguments and options
2. Resolve HTTP method (defaults to GET)
3. Resolve and normalize URL
4. Parse data parameters (key=value format)
5. Parse headers (Header:Value format)
6. Apply authentication if specified
7. Send request or prepare offline mode
8. Format and display response

### Response Formatting

- JSON responses are automatically pretty-printed
- Markdown-based output with syntax highlighting
- Configurable output sections (headers, body, or both)
- Raw mode for integration with other tools

## Troubleshooting

### Common Issues

**"command not found: yobi"**
- Ensure gem bin directory is in your PATH
- Try `bundle exec yobi` if running from source

**SSL Certificate Errors**
- Update system certificates
- Check Ruby OpenSSL installation

**JSON Parsing Errors**
- Use `--raw` mode to see actual response
- Verify API is returning valid JSON

**Permission Denied**
- Use `gem install --user-install yobi-http` for user-level installation
- Or use `sudo gem install yobi-http` for system-wide installation

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Ensure code passes RuboCop checks
6. Submit a pull request

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community guidelines.

## License

This project is open source. See the repository for license details.

## Resources

- **GitHub Repository**: https://github.com/dvinciguerra/yobi-http
- **RubyGems Package**: https://rubygems.org/gems/yobi-http
- **Changelog**: https://github.com/dvinciguerra/yobi-http/blob/main/CHANGELOG.md
- **Code of Conduct**: https://github.com/dvinciguerra/yobi-http/blob/main/CODE_OF_CONDUCT.md

## Support

For bugs and feature requests, please open an issue on GitHub:
https://github.com/dvinciguerra/yobi-http/issues
