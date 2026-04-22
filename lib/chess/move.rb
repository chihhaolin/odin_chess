module Chess
  class Move
    attr_reader :from, :to, :type, :promotion_piece

    def initialize(from:, to:, type: :normal, promotion_piece: nil)
      @from = from.freeze
      @to   = to.freeze
      @type = type
      @promotion_piece = promotion_piece
    end

    def ==(other)
      other.is_a?(Move) &&
        from == other.from &&
        to == other.to &&
        type == other.type &&
        promotion_piece == other.promotion_piece
    end

    def eql?(other) = self == other
    def hash = [from, to, type, promotion_piece].hash

    def to_s
      s = "#{file_char(from[1])}#{from[0] + 1}#{file_char(to[1])}#{to[0] + 1}"
      s += promotion_piece.to_s[0] if promotion_piece
      s
    end

    private

    def file_char(file) = ('a'.ord + file).chr
  end
end
