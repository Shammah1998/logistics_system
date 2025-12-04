-- Trigger to automatically create users table record when auth.users is created
-- This ensures every authenticated user has a corresponding record in the users table

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    user_phone TEXT;
BEGIN
    -- Extract phone from metadata, fallback to empty string if not provided
    user_phone := COALESCE(
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_app_meta_data->>'phone',
        ''
    );
    
    -- If phone is still empty, use a placeholder (you can change this behavior)
    IF user_phone = '' OR user_phone IS NULL THEN
        user_phone := 'N/A';
    END IF;
    
    -- Insert into users table
    -- SECURITY DEFINER allows this to bypass RLS policies
    INSERT INTO public.users (id, email, phone, user_type)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, ''),
        user_phone,
        'customer'::user_type_enum  -- Default to customer, can be updated later by admin
    )
    ON CONFLICT (id) DO NOTHING;  -- Prevent errors if user already exists
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the auth signup
        RAISE WARNING 'Error creating user record: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function when a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

