#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'scanf'

################################################################################
# 2次元配列
################################################################################

class Matrix
  include Enumerable

  def initialize(n, m, array = nil)
    @n = n
    @m = m
    @array = array
    @array ||= Array.new(n * m)
  end

  def [](i, j)
    @array[i * @m + j]
  end
  def []=(i, j, value)
    @array[i * @m + j] = value
  end

  def each(&proc)
    @array.each(&proc)
  end
  def each_with_index
    return enum_for(:each_with_index) unless block_given?

    (0 ... @n).each {|i|
      (0 ... @m).each {|j|
        value = @array[i * @m + j]
        yield(value, i, j)
      }
    }
  end

  def to_a
    @array
  end
  def to_s
    to_a.to_s
  end

  # 配列インスタンスごと複製する
  def clone
    Matrix.new(@n, @m, @array.clone)
  end
end

################################################################################
# ぬりかべ
################################################################################

class Nurikabe
  U = "0"
  E = " "
  F = "#"
  
  def initialize(n, m, board)
    @n = n
    @m = m
    @board = board
  end

  def to_s
    s = "\##{@n} #{@m}"
    s << "\n"
    s << @board.each_slice(@m).map {|row| row.map(&:to_s).join }.join("\n")
    s
  end

  def empty?(v)
    v == E
  end
  def number?(v)
    (v =~ /^[1-9]$/) != nil
  end
  def filled?(v)
    v == F
  end
  def decided?(v)
    empty?(v) || number?(v) || filled?(v)
  end

  ######################################
  # group
  ######################################

  # 未確定、白・数字、黒に対してそれぞれ異なる値を返却する
  def group_type(v)
    case true
    when empty?(v) || number?(v)
      1
    when filled?(v)
      2
    else
      0
    end
  end
  # 未確定と白・数字を同一視する
  def group_type_empty(v)
    v == U ? group_type(E) : group_type(v)
  end
  # 未確定と黒を同一視する
  def group_type_filled(v)
    v == U ? group_type(F) : group_type(v)
  end
  # ルックアップテーブルを作成する
  def group_map(t)
    data1 = []
    data2 = Hash.new
    next_index = 0

    t.each {|v1, v2|
      tmp1 = data1.find {|values| values.include?(v1) }
      tmp2 = data1.find {|values| values.include?(v2) }

      if !tmp1 && !tmp2
        data1.push([v1, v2])
      elsif !tmp1 && tmp2
        tmp2.push(v1)
      elsif tmp1 && !tmp2
        tmp1.push(v2)
      elsif tmp1 != tmp2
        data1.delete(tmp1)
        data1.delete(tmp2)
        data1.push(tmp1 | tmp2)
      end
    }

    data1.each {|values|
      values.each {|v| data2[v] = next_index }
      next_index += 1
    }

    data2
  end
  # 4連結ラベリングしてindexを付ける
  def group_index
    t = Matrix.new(@n, @m)
    data1 = []
    data2 = Hash.new
    next_index = 0

    t.each_with_index {|value, i, j|
      same_t = i > 0 && yield(@board[i - 1, j], @board[i, j])
      same_l = j > 0 && yield(@board[i, j - 1], @board[i, j])

      if !same_t && !same_l
        t[i, j] = next_index
        data1.push([next_index, next_index])
        next_index += 1
      elsif same_t && !same_l
        t[i, j] = t[i - 1, j]
      elsif !same_t && same_l
        t[i, j] = t[i, j - 1]
      else
        min = [t[i - 1, j], t[i, j - 1]].min
        max = [t[i - 1, j], t[i, j - 1]].max
        data1.push([min, max])
        t[i, j] = min
      end
    }

    data2 = group_map(data1)

    t.each_with_index {|value, i, j|
      t[i, j] = data2[value]
    }

    t
  end
  # 4連結ラベリングする
  def group
    return @group if @group

    proc = proc {|v1, v2| group_type(v1) == group_type(v2) }
    @group = group_index(&proc)
  end
  # 未確定を白と見做し、4連結ラベリングする
  def group_empty
    return @group_empty if @group_empty

    proc = proc {|v1, v2| group_type_empty(v1) == group_type_empty(v2) }
    @group_empty = group_index(&proc)
  end
  # 未確定を黒と見做し、4連結ラベリングする
  def group_filled
    return @group_filled if @group_filled

    proc = proc {|v1, v2| group_type_filled(v1) == group_type_filled(v2) }
    @group_filled = group_index(&proc)
  end

  ######################################
  # summary
  ######################################

  # 各エリアの文字配列を要素とする配列
  def summary
    return @summary if @summary

    h = Hash.new

    group.each_with_index {|index, i, j|
      h[index] = [] unless h.has_key?(index)
      h[index].push(@board[i, j])
    }

    @summary = h
  end
  # 未確定を白と見做したときの、各エリアの文字配列を要素とする配列
  def summary_empty
    return @summary_empty if @summary_empty

    h = Hash.new

    group_empty.each_with_index {|index, i, j|
      h[index] = [] unless h.has_key?(index)
      h[index].push(@board[i, j])
    }

    @summary_empty = h
  end
  # 未確定を黒と見做したときの、各エリアの文字配列を要素とする配列
  def summary_filled
    return @summary_filled if @summary_filled

    h = Hash.new

    group_filled.each_with_index {|index, i, j|
      h[index] = [] unless h.has_key?(index)
      h[index].push(@board[i, j])
    }

    @summary_filled = h
  end

  ######################################
  # check
  ######################################

  # 2x2以上の黒マスの固まりがあるとNG
  def check_2x2
    @board.each_with_index.map {|value, i, j|
      i > 0 && j > 0 && value == F &&
        @board[i - 0, j - 0] == @board[i - 0, j - 1] &&
        @board[i - 0, j - 1] == @board[i - 1, j - 0] &&
        @board[i - 1, j - 0] == @board[i - 1, j - 1]
    }.none?
  end
  # 黒が連結である
  # つまり黒を含むエリアの個数が1
  def check_continuity
    summary.map {|index, values| values.include?(F) }.one?
  end
  # 各エリアにおいて下記のどれかが真
  # -> すべて黒
  # -> 含まれる数字が1個 && 数字以外はすべて白 && 要素数と数字が同じ
  def check_combination
    summary.each_pair {|index, values|
      number = values.find {|v| number?(v) }
      count_e = values.count {|v| empty?(v) }
      count_n = values.count {|v| number?(v) }
      count_f = values.count {|v| filled?(v) }

      next if count_f == values.size
      next if count_n == 1 && count_e == values.size - 1 && number.to_i == values.size
      return false
    }

    true
  end
  # 回答をチェックする
  def check
    @group = @summary = nil

    check_2x2 &&
      check_continuity &&
      check_combination
  end

  # 未確定を黒と見做したとき、黒が連結である
  # つまり黒を含むエリアの個数が0または1
  def check_continuity_incomplete
    count = summary_filled.count {|index, values| values.include?(F) }
    count == 0 || count == 1
  end
  # 各エリアについて下記のどれかが真
  # -> すべて黒 || すべて白 || すべて未確定
  # -> 含まれる数字が1個 && 数字以外はすべて白 && 要素数が数字以下
  def check_combination_incomplete
    summary.each_pair {|index, values|
      number = values.find {|v| number?(v) }
      count_u = values.count {|v| !decided?(v) }
      count_e = values.count {|v| empty?(v) }
      count_n = values.count {|v| number?(v) }
      count_f = values.count {|v| filled?(v) }

      next if count_u == values.size || count_e == values.size || count_f == values.size
      next if count_n == 1 && count_e == values.size - 1 && number.to_i >= values.size
      return false
    }

    true
  end
  # 未確定を白と見做したとき、エリアがすべて白ならNG
  def check_no_number
    summary_empty.map {|index, values|
      count = values.count {|v| empty?(v) }
      count != values.size
    }.all?
  end
  # エリアの要素数が数字以下ならOK
  # -> 今後の拡張を考慮する
  def check_number_less
    summary.map {|index, values|
      number = values.find {|v| number?(v) }
      number == nil || number.to_i >= values.size
    }.all?
  end
  # 未確定を白と見做したとき、エリアの要素数が数字以上ならOK
  def check_number_more
    summary_empty.map {|index, values|
      number = values.find {|v| number?(v) }
      number == nil || number.to_i <= values.size
    }.all?
  end
  # 途中回答をチェックする
  def check_incomplete
    @group = @summary = nil
    @group_empty = @summary_empty = nil
    @group_filled = @summary_filled = nil

    check_2x2 &&
      check_continuity_incomplete &&
      check_combination_incomplete &&
      check_no_number &&
      check_number_less &&
      check_number_more
  end

  ######################################
  # decide
  ######################################

  # 数字マスが2x2の対角にある
  # -> 数字マス以外の2マスが黒で確定
  # 数字マスが1マス挟んで隣り合っている
  # -> 間の1マスが黒で確定
  def decide_neighbor
    @board.each_with_index {|value, i, j|
      if i > 0 && j > 0
        v1 = @board[i - 0, j - 0]
        v2 = @board[i - 0, j - 1]
        v3 = @board[i - 1, j - 0]
        v4 = @board[i - 1, j - 1]

        @board[i - 0, j - 1] = @board[i - 1, j - 0] = F if number?(v1) && number?(v4)
        @board[i - 0, j - 0] = @board[i - 1, j - 1] = F if number?(v2) && number?(v3)
      end

      if i >= 2
        v1 = @board[i - 2, j]
        v2 = @board[i - 0, j]

        @board[i - 1, j] = F if number?(v1) && number?(v2)
      end

      if j >= 2
        v1 = @board[i, j - 2]
        v2 = @board[i, j - 0]

        @board[i, j - 1] = F if number?(v1) && number?(v2)
      end
    }
  end
  # 未確定を白と見做したとき、数字が含まれないエリアがある
  # -> エリア内が黒で確定
  def decide_no_number
    @group_empty = @summary_empty = nil

    summary_empty.each_pair {|index, values|
      number = values.find {|v| number?(v) }
      next unless number == nil

      group_empty.each_with_index {|value, i, j|
        @board[i, j] = F if value == index
      }
    }
  end
  # 未確定を白と見做したとき、数字のあるエリアの要素数が数字と同じ
  # -> エリア内の未確定が白で確定
  def decide_number_inner
    @group_empty = @summary_empty = nil

    summary_empty.each_pair {|index, values|
      number = values.find {|v| number?(v) }
      next if number == nil || number.to_i != values.size

      group_empty.each_with_index {|value, i, j|
        @board[i, j] = E if value == index && !decided?(@board[i, j])
      }
    }
  end
  # 数字のあるエリアの要素数が数字と同じ
  # -> エリア端の上下左右が黒で確定
  def decide_number_outer
    @group = @summary = nil

    summary.each_pair {|index, values|
      number = values.find {|v| number?(v) }
      next if number == nil || number.to_i != values.size

      group.each_with_index {|value, i, j|
        next unless value == index

        @board[i - 1, j] = F if i > 0 && group[i - 1, j] != index
        @board[i, j - 1] = F if j > 0 && group[i, j - 1] != index
        @board[i + 1, j] = F if i < @n - 1 && group[i + 1, j] != index
        @board[i, j + 1] = F if j < @m - 1 && group[i, j + 1] != index
      }
    }
  end
  # 数字のあるエリアの要素数が数字未満で、隣接する未確定の個数が1
  # もしくはエリアがすべて白で、隣接する未確定の個数が1
  # -> 隣接する未確定が白で確定
  def decide_expansion
    @group = @summary = nil

    summary.each_pair {|index, values|
      number = values.find {|v| number?(v) }
      count = values.count {|v| empty?(v) }
      next if number == nil || count == values.size || number.to_i <= values.size

      data = []
      group.each_with_index {|value, i, j|
        next unless value == index

        data.push([i - 1, j]) if i > 0 && !decided?(@board[i - 1, j])
        data.push([i, j - 1]) if j > 0 && !decided?(@board[i, j - 1])
        data.push([i + 1, j]) if i < @n - 1 && !decided?(@board[i + 1, j])
        data.push([i, j + 1]) if j < @m - 1 && !decided?(@board[i, j + 1])
      }

      if data.size == 1
        i, j = data[0]
        @board[i, j] = E
      end
    }
  end
  # ルールを元に確定する
  def decide
    count = @board.count {|v| !decided?(v) }
    return if count == 0

    while true
      decide_neighbor
      decide_no_number
      decide_number_inner
      decide_number_outer
      decide_expansion

      next_count = @board.count {|v| !decided?(v) }
      return if count == next_count
      count = next_count
    end
  end

  ######################################
  # solve
  ######################################

  # 未確定マスを選択する
  def solve_find
    t = @board.each_with_index.select {|value, i, j|
      !decided?(value)
    }

    # t = t.map {|value, i, j|
    #   count = 0
    #   count += 1 if i == 0 || decided?(@board[i - 1, j])
    #   count += 1 if j == 0 || decided?(@board[i, j - 1])
    #   count += 1 if i == @n - 1 || decided?(@board[i + 1, j])
    #   count += 1 if j == @m - 1 || decided?(@board[i, j + 1])
    #   count += 1 if i == 0 || j == 0 || decided?(@board[i - 1, j - 1])
    #   count += 1 if i == 0 || j == @m - 1 || decided?(@board[i - 1, j + 1])
    #   count += 1 if i == @n - 1 || j == 0 || decided?(@board[i + 1, j - 1])
    #   count += 1 if i == @n - 1 || j == @m - 1 || decided?(@board[i + 1, j + 1])
    #   [count, i, j]
    # }

    # t = t.sort {|v1, v2| v2[0] - v1[0] }

    t.map {|count, i, j| [i, j] }
  end
  # 回答を深さ優先で探索する
  def solve
    queue = [@board]

    while !queue.empty?
      @board = queue.pop

      if check_incomplete
        # ルールを元に確定する
        decide

        # 未確定のマスを選択する
        data = solve_find

        if !data.empty?
          i, j = data[0]
          puts "DEBUG[#{i}, #{j}]:" if $DEBUG
          puts to_s if $DEBUG

          @board[i, j] = F
          queue.push(@board.clone)
          @board[i, j] = E
          queue.push(@board.clone)
        elsif check
          puts "FOUND:" if $DEBUG
          puts to_s if $DEBUG
          return
        else
          puts "NONE:" if $DEBUG
          puts to_s if $DEBUG
        end
      end
    end
  end
end

################################################################################
# エントリポイント
################################################################################

n, m = $stdin.gets.scanf("\#%d%d")
board = $stdin.read.gsub(/[\r\n]/, String.new).split(//)

nurikabe = Nurikabe.new(n, m, Matrix.new(n, m, board))
nurikabe.solve
puts nurikabe