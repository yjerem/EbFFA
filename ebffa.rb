require 'bloops'

SOUND = Bloops.sound Bloops::SQUARE

class Note
  attr_accessor :semitones, :letter, :accidental

  def initialize(semitones, letter, accidental = :n)
    @semitones, @letter, @accidental = semitones, letter, accidental
  end

  def ==(other)
    @semitones == other.semitones
  end

  def <=>(other)
    @semitones <=> other.semitones
  end

  def >(other)
    @semitones > other.semitones
  end

  def <(other)
    @semitones < other.semitones
  end

  def +(interval)
    new_semitones = @semitones + interval.semitones
    new_letter = _add_note_letter(@letter, interval.interval)

    new_letter_semitones = _letter_to_semitones(new_letter)
    offset = (new_letter_semitones % 12) - (new_semitones % 12)

    new_accidental = { -2 => :ss, -1 => :s, 0 => :n, 1 => :b, 2 => :bb }[offset]

    Note.new(new_semitones, new_letter, new_accidental)
  end

  def -(interval)
    self + interval.below
  end

  def octave
    @semitones / 12 + 4
  end

  def va(octave)
    new_interval = (@semitones % 12) + ((octave - 4) * 12)
    Note.new(new_interval, @letter, @accidental)
  end

  def play
    b = Bloops.new
    b.tune SOUND, bloops_note
    b.play
    sleep(0.1) until b.stopped?
  end

  def bloops_note
    note = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'][@semitones % 12]
    note + octave.to_s
  end

  def to_s
    accidentals = { :n => '', :b => 'b', :bb => 'bb', :s => '#', :ss => '##' }
    @letter.to_s + accidentals[@accidental] + octave.to_s
  end

  def inspect
    "note " + to_s
  end

  def _add_note_letter(letter, interval)
    if interval > 0
      interval -= 1
    else
      interval += 1
    end
    num = letter.to_s[0] - ?A
    num += interval
    num %= 7
    (num + ?A).chr
  end

  def _letter_to_semitones(letter)
    { :C => 0, :D => 2, :E => 4, :F => 5, :G => 7, :A => 9, :B => 11 }[letter.to_sym]
  end
end

C  = Note.new(0, :C)
Bs = Note.new(0, :B, :s)
Cs = Note.new(1, :C, :s)
Db = Note.new(1, :D, :b)
D  = Note.new(2, :D)
Ds = Note.new(3, :D, :s)
Eb = Note.new(3, :E, :b)
E  = Note.new(4, :E)
Fb = Note.new(4, :F, :b)
F  = Note.new(5, :F)
Es = Note.new(5, :E, :s)
Fs = Note.new(6, :F, :s)
Gb = Note.new(6, :G, :b)
G  = Note.new(7, :G)
Gs = Note.new(8, :G, :s)
Ab = Note.new(8, :A, :b)
A  = Note.new(9, :A)
As = Note.new(10, :A, :s)
Bb = Note.new(10, :B, :b)
B  = Note.new(11, :B)
Cb = Note.new(11, :C, :b)

class Interval
  attr_accessor :semitones, :quality, :interval

  def initialize(semitones, quality, interval)
    @semitones, @quality, @interval = semitones, quality, interval
  end

  def below
    Interval.new(-@semitones, quality, -@interval)
  end

  def to_s
    qualities = { :per => 'P', :dim => 'D', :min => 'Mn', :maj => 'M', :aug => 'A' }

    if @interval < 0
      qualities[@quality] + @interval.abs.to_s + ' B'
    else
      qualities[@quality] + @interval.to_s + ' A'
    end
  end

  def inspect
    "interval " + to_s
  end
end

P1  = Interval.new(0,  :per, 1)
D2  = Interval.new(0,  :dim, 2)
Mn2 = Interval.new(1,  :min, 2)
M2  = Interval.new(2,  :maj, 2)
A2  = Interval.new(3,  :aug, 2)
D3  = Interval.new(2,  :dim, 3)
Mn3 = Interval.new(3,  :min, 3)
M3  = Interval.new(4,  :maj, 3)
A3  = Interval.new(5,  :aug, 3)
D4  = Interval.new(4,  :dim, 4)
P4  = Interval.new(5,  :per, 4)
A4  = Interval.new(6,  :aug, 4)
D5  = Interval.new(6,  :dim, 5)
P5  = Interval.new(7,  :per, 5)
A5  = Interval.new(8,  :aug, 5)
D6  = Interval.new(7,  :dim, 6)
Mn6 = Interval.new(8,  :min, 6)
M6  = Interval.new(9,  :maj, 6)
A6  = Interval.new(10, :aug, 6)
D7  = Interval.new(9,  :dim, 7)
Mn7 = Interval.new(10, :min, 7)
M7  = Interval.new(11, :maj, 7)
A7  = Interval.new(12, :aug, 7)
D8  = Interval.new(11, :dim, 8)
P8  = Interval.new(12, :per, 8)
A8  = Interval.new(13, :aug, 8)

class Chord
  include Enumerable

  attr_accessor :notes

  def initialize(notes)
    @notes = notes
  end

  def each
    @notes.each do |note|
      yield note
    end
  end

  def play(how = :harmonic)
    b = Bloops.new
    case how
    when :harmonic
      @notes.each do |note|
        b.tune SOUND, note.bloops_note
      end
    when :melodic
      b.tune SOUND, @notes.map { |note| note.bloops_note }.join(" ")
    end
    b.play
    sleep(0.1) until b.stopped?
  end

  def inspect
    "chord " + @notes.map { |note| note.to_s }.join(", ")
  end

  def invert
    chord = self.dup
    chord.invert!
    chord
  end

  def invert!
    min = @notes.delete(@notes.min)
    max = @notes.max

    min += P8 until min > max

    @notes << min
  end

  def self.triad(tonic, quality = :maj, inversion = 0)
    case quality
    when :maj
      c = new [tonic, tonic + M3, tonic + P5]
    when :min
      c = new [tonic, tonic + Mn3, tonic + P5]
    when :dim
      c = new [tonic, tonic + Mn3, tonic + D5]
    when :halfdim
      c = new [tonic, tonic + M3, tonic + D5]
    end
    inversion.times { c.invert! }
    c
  end

  def self.v7(tonic, inversion = 0)
    root = tonic + P5
    c = new [root, root + M3, root + P5, root + Mn7]
    inversion.times { c.invert! }
    c
  end

  def self.o7(tonic, inversion = 0)
    root = tonic - Mn2
    c = new [root, root + Mn3, root + D5, root + D7]
    inversion.times { c.invert! }
    c
  end
end
