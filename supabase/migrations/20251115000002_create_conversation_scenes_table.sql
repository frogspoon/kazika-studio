-- Create conversation_scenes table for storing scene descriptions for each message
CREATE TABLE IF NOT EXISTS kazikastudio.conversation_scenes (
  id BIGSERIAL PRIMARY KEY,
  message_id BIGINT NOT NULL REFERENCES kazikastudio.conversation_messages(id) ON DELETE CASCADE,
  scene_description TEXT NOT NULL,
  scene_order INT NOT NULL DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT unique_message_scene_order UNIQUE (message_id, scene_order)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_conversation_scenes_message_id
  ON kazikastudio.conversation_scenes(message_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE kazikastudio.conversation_scenes ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all scenes
CREATE POLICY "Allow authenticated users to read conversation scenes"
  ON kazikastudio.conversation_scenes
  FOR SELECT
  TO authenticated
  USING (true);

-- Policy: Allow authenticated users to insert scenes
CREATE POLICY "Allow authenticated users to insert conversation scenes"
  ON kazikastudio.conversation_scenes
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy: Allow authenticated users to update scenes
CREATE POLICY "Allow authenticated users to update conversation scenes"
  ON kazikastudio.conversation_scenes
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Policy: Allow authenticated users to delete scenes
CREATE POLICY "Allow authenticated users to delete conversation scenes"
  ON kazikastudio.conversation_scenes
  FOR DELETE
  TO authenticated
  USING (true);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION kazikastudio.update_conversation_scenes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER conversation_scenes_updated_at
  BEFORE UPDATE ON kazikastudio.conversation_scenes
  FOR EACH ROW
  EXECUTE FUNCTION kazikastudio.update_conversation_scenes_updated_at();

-- Add comment to table
COMMENT ON TABLE kazikastudio.conversation_scenes IS 'Stores scene descriptions for conversation messages, enabling visual/cinematic representation of dialogue';
COMMENT ON COLUMN kazikastudio.conversation_scenes.scene_description IS 'Detailed description of the scene including character expressions, movements, and environment';
COMMENT ON COLUMN kazikastudio.conversation_scenes.scene_order IS 'Order of scene within a message (for messages with multiple scenes)';
