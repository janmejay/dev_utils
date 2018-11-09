// A tool to read select columns of a quoted-csv

// Rows in source csv should look like:
// foo,bar baz,baz,quux
// foo,"bar baz",quux,grault
// foo,"bar\"baz",quux,grault
// etc.

// Invocation: 'qcsv 2 4' should print json-arrays
// containing "bar baz" and "quux" for the first row
// "bar\"baz" and "quux" for the last row... etc.

#include <iostream>
#include <cstdint>
#include <vector>
#define RAPIDJSON_HAS_STDSTRING 1
#include <rapidjson/prettywriter.h>

std::runtime_error mk_error(std::string&& str) {
  return std::runtime_error(str);
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> parse_row(
  const std::string& row,
  std::uint32_t row_num) {

  bool quote_on = false;
  bool escape_on = false;
  std::uint32_t col_start = 0;
  char prev_ch, next_ch = 0, curr_ch;
  std::vector<std::pair<std::uint32_t, std::uint32_t>> col_offsets;
  auto row_len = row.length();
  for (std::uint32_t i = 0; i < row_len; i++) {
    if (i > 0) {
      prev_ch = curr_ch;
    }
    curr_ch = row[i];
    if (i + 1 < row_len) {
      next_ch = row[i + 1];
    }
    if (! quote_on && curr_ch == ',') {
      col_offsets.push_back({col_start, i});
      col_start = i + 1;
    }
    if (curr_ch == '\\') {
      escape_on = !escape_on;
      continue;
    }
    if (escape_on) {
      escape_on = false;
      continue;
    }
    if (quote_on && curr_ch == '"') {
      if (next_ch == ',') {
        quote_on = false;
        continue;
      } else {
        throw mk_error(
          "Invalid data @ row: " + std::to_string(row_num) +
          " and char " + std::to_string(i) +
          " expected ',' found '" + next_ch + "'");
      }
    }
    if (! quote_on && curr_ch == '"') {
      if (i > 0 && prev_ch != ',') {
        throw mk_error(
          "Invalid data @ row: " + std::to_string(row_num) +
          " and char " + std::to_string(i) +
          " quoted data started mid-cell");
      }
      quote_on = true;
    }
  }
  if (col_start < row_len) {
    col_offsets.push_back({col_start, row_len});
  }

  return col_offsets;
}

void print_rows(std::vector<std::uint32_t>&& cols_of_interest) {
  std::uint32_t row_num = 0;
  std::string row;

  while (std::getline(std::cin, row)) {
    // looking for comma is ok because a utf8 code-pt is encoded as
    // 0*******             for U+0000 - U+007F so each byte is [0, 0x7F]
    // 110*****, 10******   for U+0080 - U+07FF
    //    so each byte is [0xC0, 0xDF] U [0x80, 0xBF] which implies >= 0x80
    // 1110****, 10******x2 for U+0800 - U+FFFF
    //    so each byte is [0xE0, 0xEF] U [0x80, 0xBF] which implies >= 0x80
    // 11110***, 10******x3 for U+10000 - U+10FFFF
    //    so each byte is [0xF0, 0xF7] U [0x80, 0xBF] which implies >= 0x80
    // and comma ',' is '0x2C', '\' is 0x5C and '"' is 0x22, so all are < 0x80
    auto col_offsets = parse_row(row, row_num);
    row_num++;

    if (cols_of_interest.empty()) {
      for (std::uint32_t i = 0; i < col_offsets.size(); i++) {
        cols_of_interest.push_back(i);
      }
    }

    rapidjson::StringBuffer sb;
    rapidjson::PrettyWriter<rapidjson::StringBuffer> writer(sb);
    writer.StartArray();
    for (auto icol : cols_of_interest) {
      if (icol < col_offsets.size()) {
        auto offset = col_offsets[icol];
        auto len = offset.second - offset.first;
        if (len > 0) {
          writer.String(
            row.c_str() + offset.first,
            offset.second - offset.first,
            false);
        } else {
          writer.String("");
        }
      } else {
        writer.Null();
      }
    }
    writer.EndArray();
    std::puts(sb.GetString());
  }
}

int main(int argc, char** argv) {
  try {
    std::vector<std::uint32_t> cols_of_interest;
    for (int i = 1; i < argc; i++) {
      auto col = std::stoul(argv[i]);
      cols_of_interest.push_back(col);
    }
    print_rows(std::move(cols_of_interest));
  } catch (const std::exception& e) {
    std::cerr << "Error: " << e.what() << "\n";
    return 1;
  }
}
