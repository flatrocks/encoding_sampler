# EncodingSampler

EncodingSampler helps solve the problem of what to do when you don't know the character encoding of a file.
It was initially created to solve the typical problem of selecting an appropriate encoding for an uploaded user
file where the user also has no idea of the encoding (or typically, even what "character encoding" means.)

For a given file, some encodings may be dismissed out of hand because they would result in invalid
characters or sequences.  However, in the general case you have to let the user see the differences and choose.
For example, it's easy to determine that an 8-bit character is _not_ encoded as US_ASCII because it is simply invalid, 
but it's impossible to tell whether the character __0xA4__ should be displayed as a 
generic currency symbol (&curren;) using ISO-8859-1 or as a Euro symbol (&euro;) using ISO-8859-15
without asking the user.

EncodingSampler solves the problem by collecting a reasonably (but not rigorously) minimal sample by reading the file line-by-line.  Lines that demonstrate the difference between any pair of encodings are noted, and when a line is encountered that cannot be "decoded" with a specific encoding, that encoding is considered invalid and removed from the running.  When the sampling is complete, each encoding is grouped with other encoding(s) that yield identical decoding results.

There are three possible results:
* There may be no valid encodings.  This could mean that none of the proposed encodings match the file, but often it means the file is simply malformed.  This is generally what you will see if you try to determine the encoding of a non-text binary file.
* There may be only one group of valid encodings, all of which yield the same decoded data.  In this case there are no samples to look at because there are no encodings to differentiate between.  A straight ASCII file may yield this result for many encodings.
* There may be more than one set of valid encodings, each if which yields a different decoded data.  This is the interesting case!  Then samples will be available so a user can visually determine which is the correct interpretation.  The "diff-lcs" gem is used to diff the samples, providing a simple way to highlight the (usually few) differences.

## Performance

Because this method works by reading file lines and "decoding" each line with all the remaining valid encodings, it can be slow. For most files, the number of line "decodings" will equal the number of lines in the file times the number of encodings tested, and at this writing, Ruby 1.9.3 supports 168 encodings!  It's recommended to try and use a much smaller set.

## Installation

Add this line to your application's Gemfile:

    gem 'encoding_sampler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install encoding_sampler

## Usage

Creating a new EncodingSampler instantiates a new instance and completes the file analysis.

    EncodingSampler.new(file_name, options = {}} → new_encoding_sampler
    
    options:
      :difference_start => 
      :difference_end =>

Once you have an instance of an EncodingSampler, you can use the objects instance methods to determine which encodings are valid, which are unique (that is, which yield unique results,) and get samples to compare the differences visually.  For example, imagining you have a file that turns out to be ISO-8859-15 (which includes the Euro sign,) you might get these results:

```ruby
    # Create a new sampler. The heavy lifting is done at initialization.
    # After the Sampler is created, there's no additional file processing overhead.
    sampler = EncodingSampler::Sampler.new(
      'some/file/name.csv', 
      ['ASCII-8BIT', 'UTF-8', 'ISO-8859-1', 'ISO-8859-2, 'ISO-8859-15'])

    # List valid encodings
    sampler.valid_encodings
            # ["ASCII-8BIT", "ISO-8859-1","ISO-8859-2", "ISO-8859-15"]
            # (UTF-8 was dropped because it was invliad for one or more lines in the sample file.)

    sampler.unique_valid_encodings
            # [["ASCII-8BIT"], ["ISO-8859-1", 'ISO-8859-2'], ["ISO-8859-15"]]
            # (ISO-8859-1 and ISO-8859-2 are grouped tegether because they yielded identical decoding results.)

    # The payoff: samples for each encoding, individually...
    sampler.sample('ASCII-8BIT')
            # ["?ABCDEFabcdef0123456789?ABCDEFabcdef0123456789?"]
    sampler.sample('ISO-8859-1')
            # ["¤ABCDEFabcdef0123456789¤ABCDEFabcdef0123456789¤"]
    sampler.sample('ISO-8859-15')
            # ["€ABCDEFabcdef0123456789€ABCDEFabcdef0123456789€"]
    # or all together...
    sampler.samples(["ASCII-8BIT", "ISO-8859-1", "ISO-8859-15"])
            # {"ASCII-8BIT"=>["?ABCDEFabcdef0123456789?ABCDEFabcdef0123456789?"], 
            #   "ISO-8859-1"=>["¤ABCDEFabcdef0123456789¤ABCDEFabcdef0123456789¤"], 
            #   "ISO-8859-15"=>["€ABCDEFabcdef0123456789€ABCDEFabcdef0123456789€"]}

    # Finally, you can "diff" the results so it's easy to see the differences:
    sampler.diffed_samples(["ASCII-8BIT", "ISO-8859-1", "ISO-8859-15"])
            # {"ASCII-8BIT"=>["<span class=\"difference\">?</span>ABCDEFabcdef0123456789<span class=\"difference\">?</span>ABCDEFabcdef0123456789<span class=\"difference\">?</span>"], 
            #   "ISO-8859-1"=>["<span class=\"difference\">¤</span>ABCDEFabcdef0123456789<span class=\"difference\">¤</span>ABCDEFabcdef0123456789<span class=\"difference\">¤</span>"], 
            #   "ISO-8859-15"=>["<span class=\"difference\">€</span>ABCDEFabcdef0123456789<span class=\"difference\">€</span>ABCDEFabcdef0123456789<span class=\"difference\">€</span>"]}

In raw form the `diffed_samples` don't seem impressive, but they can display the resuls via HTML, for example, to highlight and clarify the differences:

<table>
<tr>
  <th>ASCII-8BIT</th>
  <td><span style="font-weight:bold; color:#ff0000;">?</span>ABCDEFabcdef0123456789<span style="font-weight:bold; color:#ff0000;">?</span>ABCDEFabcdef0123456789<span style="font-weight:bold; color:#ff0000;">?</span></td>
</tr>
<tr>
  <th>ISO-8859-1</th>
  <td><span style="font-weight:bold; color:#ff0000;">¤</span>ABCDEFabcdef0123456789<span style="font-weight:bold; color:#ff0000;">¤</span>ABCDEFabcdef0123456789<span style="font-weight:bold; color:#ff0000;">¤</span></td>
</tr>
  <th>ISO-8859-15</th>
  <td><span style="font-weight:bold; color:#ff0000;">€</span>ABCDEFabcdef0123456789<span style="font-weight:bold; color:#ff0000;">€</span>ABCDEFabcdef0123456789<span style="font-weight:bold; color:#ff0000;">€</span></td>
</tr>
</table>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
