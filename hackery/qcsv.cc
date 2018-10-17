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
#include <UTF8Strings-1/String.h>
#define RAPIDJSON_HAS_STDSTRING 1
#include <rapidjson/prettywriter.h>

std::runtime_error mk_error(std::string&& str) {
  return std::runtime_error(str);
}

std::vector<std::pair<std::uint32_t, std::uint32_t>> parse_row(
  const UTF8::String& row,
  std::uint32_t row_num) {

  bool quote_on = false;
  bool escape_on = false;
  std::uint32_t col_start = 0;
  UTF8::String prev_ch, next_ch, curr_ch;
  std::vector<std::pair<std::uint32_t, std::uint32_t>> col_offsets;
  for (std::uint32_t i = 0; i < row.Length(); i++) {
    if (i > 0) {
      prev_ch = curr_ch;
    }
    if (next_ch.Length() == 1) {
      curr_ch = next_ch;
    } else {
      curr_ch = row[i];
    }
    if (i + 1 < row.Length()) {
      next_ch = row[i + 1];
    }
    if (! quote_on && curr_ch.CharacterIsOneOfThese(",")) {
      col_offsets.push_back({col_start, i});
      col_start = i + 1;
    }
    if (curr_ch.CharacterIsOneOfThese("\\")) {
      escape_on = !escape_on;
      continue;
    }
    if (escape_on) {
      escape_on = false;
      continue;
    }
    if (quote_on && curr_ch.CharacterIsOneOfThese("\"")) {
      if (next_ch.CharacterIsOneOfThese(",")) {
        quote_on = false;
        continue;
      } else {
        throw mk_error(
          "Invalid data @ row: " + std::to_string(row_num) +
          " and char " + std::to_string(i) +
          " expected ',' found '" + next_ch.ToString() + "'");
      }
    }
    if (! quote_on && curr_ch.CharacterIsOneOfThese("\"")) {
      if (i > 0 && ! prev_ch.CharacterIsOneOfThese(",")) {
        throw mk_error(
          "Invalid data @ row: " + std::to_string(row_num) +
          " and char " + std::to_string(i) +
          " quoted data started mid-cell");
      }
      quote_on = true;
    }
  }
  if (col_start < row.Length()) {
    col_offsets.push_back({col_start, row.Length()});
  }

  return col_offsets;
}

void print_rows(std::vector<std::uint32_t>&& cols_of_interest) {
  std::uint32_t row_num = 0;
  std::string raw_chars;

  while (std::getline(std::cin, raw_chars)) {
    UTF8::String row(raw_chars);
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
          auto str = row
            .Substring(offset.first, offset.second - offset.first)
            .ToString();
          writer.String(str);
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
